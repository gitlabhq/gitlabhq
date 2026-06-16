# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'optparse'
require 'shellwords'
require 'uri'
require 'yaml'

require 'rainbow'

require_relative 'env'
require_relative 'graphql_client'
require_relative 'workspace'
require_relative 'sync/diff'
require_relative 'sync/workflow'
require_relative 'sync/auto_mr'
require_relative 'sync/manifest'

module Gitlab
  module PrinciplesDistiller
    # Orchestrates the per-principle distillation pipeline: load the
    # manifest, decide which principles drifted, drive the Duo Workflow
    # API to refresh them, and (optionally) open a follow-up MR.
    class Sync
      include AutoMr

      # Cap concurrent Duo Workflow invocations to avoid scheduling too many
      # child CI pipelines at once during a full re-distillation (~23 principles).
      MAX_CONCURRENT_DISTILLATIONS = 4

      DISTILL_MAX_RETRIES = 3

      # Backoffs are long because the most common failure is transient
      # Gitaly node overload on the promisor partial-clone fetch; retrying
      # immediately would hit the same overloaded node.
      DISTILL_RETRY_BACKOFF_SECONDS = [300, 900, 1800].freeze

      def self.run
        new.run
      end

      def manifest
        @manifest ||= Manifest.new
      end

      def workflow
        @workflow ||= Workflow.new(manifest: manifest)
      end

      def run
        options = parse_options

        workflow.validate_config! unless options[:dry_run]

        banner("Loading manifest from #{Manifest::MANIFEST_PATH}...")
        manifest.load

        # In --push mode the static artifacts (AGENTS.md, CLAUDE.md, both
        # SKILL.md files) are regenerated inside the dedicated tooling branch
        # during publish, so they don't leak into the per-team branches.
        # Outside --push we write them straight to the working tree as before.
        regenerate_static_artifacts unless options[:push]

        banner("\nScanning principles for stale SSOT sources...")
        affected = manifest.affected_principles(force: options[:force], only: options[:only])

        if affected.empty?
          puts "\n#{Rainbow('All principles are up to date.').green}"
          return
        end

        puts "\n#{Rainbow("Affected principles: #{affected.keys.join(', ')}").yellow}"

        if options[:dry_run]
          puts "\n#{Rainbow('[DRY RUN]').cyan} Would re-distill #{affected.size} principle(s)."
          return
        end

        contents, failed = distill(affected, options)
        return if contents.empty? && failed.empty?

        puts "\n#{Rainbow("#{contents.size} principle(s) updated.").green}"
        abort_on_failures(failed)

        publish(contents, affected, push: options[:push])
      end

      # Writes go straight to the working tree. In --push mode disk writes
      # are deferred (see build_distilled_contents) until after the publish
      # branch is checked out, so the resulting MR diff contains ONLY the
      # distilled files.
      def distill_and_write_principles(affected, rewrite: false)
        results, failed = build_distilled_contents(affected, rewrite: rewrite)
        results.each do |name, content|
          path = manifest.principles_path(name)
          File.write(Workspace.safe_join(path), content)
          puts "  #{name}: #{Rainbow("updated and written to #{path}").green}"
        end

        [results, failed]
      end

      def parse_options
        options = {}
        OptionParser.new do |opts|
          opts.banner = 'Usage: gitlab-ai-principles-distiller-sync [options]'

          opts.on('--workspace PATH', 'Path to the repository workspace ' \
            '(defaults to $CI_PROJECT_DIR)') do |path|
            Workspace.path = File.expand_path(path)
          end

          opts.on('--dry-run', 'Show what would be done without making changes') do
            options[:dry_run] = true
          end

          opts.on('--push', 'After distillation, create a branch, commit, push, and open an MR') do
            options[:push] = true
          end

          opts.on('--force', 'Force re-distillation of all principles, ignoring checksums') do
            options[:force] = true
          end

          opts.on('--only NAMES', 'Comma-separated list of principle names to process') do |names|
            options[:only] = names.split(',').map(&:strip)
          end

          opts.on('--rewrite', 'Drop rule 9 (preserve wording) so Duo rewrites all items from scratch') do
            options[:rewrite] = true
          end
        end.parse!

        options
      end

      # Informational only; the Duo agent reads the file itself via the
      # Workflow API.
      def announce_distillation_start(name, mutex)
        log = ->(msg) { mutex ? mutex.synchronize { puts msg } : puts(msg) }

        if File.exist?(Workspace.safe_join(manifest.principles_path(name)))
          log.call(Rainbow("  #{name}: distilling (existing file found)...").faint)
        else
          log.call(Rainbow("  #{name}: no existing file — regenerating from scratch...").yellow)
        end
      end

      private

      def distill(affected, options)
        contents, failed =
          if options[:push]
            build_distilled_contents(affected, rewrite: options[:rewrite])
          else
            distill_and_write_principles(affected, rewrite: options[:rewrite])
          end

        puts "\n#{Rainbow('No meaningful principle updates needed.').faint}" if contents.empty? && failed.empty?

        [contents, failed]
      end

      def abort_on_failures(failed)
        return if failed.empty?

        abort "\n#{Rainbow("ERROR: #{failed.size} principle(s) failed after retries: #{failed.join(', ')}").red}"
      end

      def publish(contents, affected, push:)
        unless push
          puts "\n#{Rainbow('[LOCAL]').cyan} Distillation complete. Pass --push to create a branch and MR."
          return
        end

        create_branch_and_mr(contents, affected, manifest.auto_mr_config)
      end

      def banner(message)
        puts Rainbow(message).bold
      end

      def regenerate_static_artifacts
        banner("\nUpdating AGENTS.md context loading section...")
        manifest.generate_agents_md_context_loading

        banner("\nGenerating gitlab-coding-principles skill (.agents/skills/ + .claude/skills/)...")
        manifest.generate_principles_skill

        banner("\nGenerating per-file CODEOWNERS rules...")
        manifest.generate_codeowners

        banner("\nInjecting prerequisite notes into distilled files...")
        manifest.inject_prerequisite_notes
      end

      # Returns [{principle_name => fully_assembled_file_content}, [failed_names]]
      # without writing to disk, so --push mode can defer writes until after
      # the publish branch is checked out off origin/master.
      def build_distilled_contents(affected, rewrite: false)
        header = '<!-- Auto-generated from docs.gitlab.com by ' \
          "gitlab-ai-principles-distiller — do not edit manually -->\n\n"

        results = parallel_distill(affected, rewrite: rewrite)

        failed = []
        contents = {}

        affected.each_key do |name|
          current, updated = results[name]

          if updated.nil?
            failed << name
            next
          end

          updated = Diff.reduce_noise(current, updated) if current

          config = manifest.principle_config(name)

          # Assemble the full body (header + prerequisite note + sources
          # footer) BEFORE the meaningful? gate. `current` is read from disk
          # with its footer intact (strip_frontmatter removes only the YAML),
          # so comparing the raw checklist against it always looked
          # "meaningful" and produced frontmatter-only MRs. Comparing the
          # fully-assembled body against `current` makes the gate symmetric.
          assembled = assemble_distilled_body(updated, config, name, header)

          unless Diff.meaningful?(current, assembled)
            puts "  #{name}: #{Rainbow('no meaningful changes').faint}"
            next
          end

          checksum = manifest.compute_checksum(config)
          contents[name] = <<~CONTENT
        ---
        source_checksum: #{checksum}
        distilled_at_sha: #{distillation_base_sha}
        ---
        #{assembled}
          CONTENT
        end

        [contents, failed]
      end

      # Builds the full distilled body: auto-generated header, optional
      # prerequisite note, the distilled checklist, and the authoritative
      # sources footer. Matches what read_principles_file returns for an
      # already-published file (sans YAML frontmatter), so the result can be
      # compared against `current` by Diff.meaningful?.
      def assemble_distilled_body(updated, config, name, header)
        note = manifest.prerequisite_note(name)

        updated = "#{header}#{updated}" unless updated.start_with?('<!-- Auto-generated')
        updated = updated.sub(/^(<!-- Auto-generated.*-->)\n\n*/, "\\1\n\n#{note}") if note
        "#{updated.rstrip}\n\n#{manifest.sources_footer(config)}"
      end

      # `mutex` serialises log output and writes to `results`.
      # Manifest#read_repo_file owns its own mutex for the SSOT file cache.
      # Manifest must be loaded before forking; otherwise the unsynchronized
      # `@data ||= load` in Manifest#data would race.
      def parallel_distill(affected, rewrite: false)
        raise 'manifest must be loaded before parallel_distill' unless manifest.loaded?

        mutex = Mutex.new
        results = {}

        affected.each_slice(MAX_CONCURRENT_DISTILLATIONS) do |batch|
          threads = batch.map do |name, info|
            Thread.new do
              current = read_principles_file(name)
              updated = distill_principle(name, info[:config], mutex: mutex, rewrite: rewrite)
              mutex.synchronize { results[name] = [current, updated] }
            end
          end
          threads.each(&:join)
        end

        results
      end

      def distill_principle(name, config, mutex: nil, rewrite: false)
        log = ->(msg) { mutex ? mutex.synchronize { puts msg } : puts(msg) }
        log_warn = ->(msg) { mutex ? mutex.synchronize { warn msg } : warn(msg) }

        announce_distillation_start(name, mutex)
        workflow.validate_sources!(config) # raises if any SSOT source is missing on disk

        log_warn.call(Rainbow("  WARNING: --rewrite is a no-op with the Workflow API backend").yellow) if rewrite

        updated = nil
        DISTILL_MAX_RETRIES.times do |attempt|
          if attempt.positive?
            backoff = DISTILL_RETRY_BACKOFF_SECONDS[attempt - 1]
            log.call(Rainbow("  Waiting #{backoff}s before retry #{attempt} for #{name}...").faint)
            workflow.sleep_with_heartbeat(backoff, "retry #{attempt} for #{name}", log)
          end

          log.call("  Triggering Duo Workflow for #{name}#{" (retry #{attempt})" if attempt.positive?}...")
          result = workflow.distill(name, config)

          if result&.include?('## Checklist')
            updated = result
            break
          end

          msg = "  WARNING: Duo returned invalid content for #{name} (attempt #{attempt + 1}/#{DISTILL_MAX_RETRIES})"
          log_warn.call(Rainbow(msg).yellow)

          unless result.nil?
            preview = result.gsub(/\s+/, ' ').strip.slice(0, 200)
            log_warn.call(Rainbow("  Response preview: #{preview}...").faint)
          end
        end

        unless updated
          log_warn.call(Rainbow("  ERROR: Duo failed after #{DISTILL_MAX_RETRIES} attempts for #{name}").red)
          return
        end

        Diff.strip_preamble(updated)
      end

      # Returns the distilled file content stripped of its YAML frontmatter,
      # or nil if no file exists yet.
      def read_principles_file(name)
        path = Workspace.safe_join(manifest.principles_path(name))
        return unless File.exist?(path)

        manifest.strip_frontmatter(File.read(path))
      end
    end
  end
end
