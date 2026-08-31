# frozen_string_literal: true

require 'openssl'
require 'fileutils'
require 'json'
require 'net/http'
require 'shellwords'
require 'uri'
require 'yaml'

require 'rainbow'

require_relative 'env'
require_relative 'flow_definition'
require_relative 'graphql_client'
require_relative 'workspace'
require_relative 'sync/diff'
require_relative 'sync/links'
require_relative 'sync/duo_instructions'
require_relative 'sync/workflow'
require_relative 'sync/reviewer_resolver'
require_relative 'sync/auto_mr'
require_relative 'sync/manifest'
require_relative 'sync/validator'
require_relative 'sync/artifacts'
require_relative 'sync/child_pipeline'
require_relative 'sync/cli'

module Gitlab
  module PrinciplesDistiller
    # Orchestrates the per-principle distillation pipeline: load the manifest, decide which principles drifted, drive
    # the Duo Workflow API to refresh them, and (optionally) open a follow-up MR.
    class Sync
      include AutoMr

      # Cap concurrent Duo Workflow invocations to avoid scheduling too many child CI pipelines at once during a full
      # re-distillation (~23 principles).
      MAX_CONCURRENT_DISTILLATIONS = 4

      DISTILL_MAX_RETRIES = 3

      # Backoffs are long because the most common failure is transient Gitaly node overload on the promisor
      # partial-clone fetch; retrying immediately would hit the same overloaded node.
      DISTILL_RETRY_BACKOFF_SECONDS = [300, 900, 1800].freeze

      # Baseline drift is DETERMINISTIC: the same SSOT sources and baseline produce the same drift on every attempt, so
      # the long Gitaly-oriented backoff above is pure waste - the retry re-runs the identical input.
      # When the prior attempt failed on baseline drift (not a transient fetch/agent error), retry almost immediately so
      # a systematic baseline mismatch fails fast (~seconds) instead of consuming ~24 min of backoff and risking the
      # job-level timeout.
      # A small non-zero wait still lets genuinely nondeterministic agent output settle.
      DISTILL_BASELINE_DRIFT_BACKOFF_SECONDS = 5

      # Documentation pointer shown on failure so an author who trips the check-fences guard (it also runs on
      # doc/**/*.md changes) knows where to get context.
      # Links the published docs page rather than a repo path, since it renders as a clickable URL in the CI log.
      DUO_INSTRUCTIONS_DOC = 'https://docs.gitlab.com/development/documentation/ai-instruction-files-documentation/'

      # Path of the per-run dotenv report consumed by the `ai-principles-report-failure` Slack job, so its message can
      # name the failed principles instead of a generic "the job failed".
      RUN_REPORT_PATH = 'tmp/ai-principles-run.env'

      # Where the generator writes the child-pipeline YAML, and where each distill job writes its per-principle
      # artifacts for the collect job to fan back in. Both are under tmp/ so they never pollute a publish diff.
      CHILD_PIPELINE_PATH = 'tmp/ai-principles-child-pipeline.yml'
      ARTIFACTS_DIR = 'tmp/ai-principles-distilled'
      DistillationRun = Data.define(:affected, :target_sha)

      # A thematic break (`---`, `***`, or `___` alone on a line) is Markdown document scaffolding, not a rule, so
      # `logical_units` treats it as a unit boundary rather than comparable baseline content (observed with
      # testing-frontend-testing-hierarchy's `---` divider, job 15601793108).
      THEMATIC_BREAK = /\A(?:-{3,}|\*{3,}|_{3,})\z/

      def manifest
        @manifest ||= Manifest.new
      end

      def workflow
        @workflow ||= Workflow.new(manifest: manifest)
      end

      # The default, single-job path: scan, distill everything affected in this process, and publish. Still used for
      # local runs and as the in-process fallback; scheduled CI now splits these stages across jobs (see
      # generate_child_pipeline / distill_one / collect).
      def distill_and_publish(options)
        workflow.validate_config!(push: options[:push]) unless options[:dry_run]

        banner("Loading manifest from #{Manifest::MANIFEST_PATH}...")
        manifest.load

        # In --push mode the static artifacts (AGENTS.md, CLAUDE.md, both SKILL.md files) are regenerated inside the
        # dedicated tooling branch during publish, so they don't leak into the per-team branches.
        # Outside --push we write them straight to the working tree as before.
        regenerate_static_artifacts unless options[:push]

        banner("\nScanning principles for stale SSOT sources...")
        affected = manifest.affected_principles(force: options[:force], only: options[:only])

        if affected.empty?
          puts "\n#{Rainbow('All principles are up to date.').green}"
          write_run_report([], 0)
          return
        end

        puts "\n#{Rainbow("Affected principles: #{affected.keys.join(', ')}").yellow}"

        if options[:dry_run]
          puts "\n#{Rainbow('[DRY RUN]').cyan} Would re-distill #{affected.size} principle(s)."
          return
        end

        contents, failed = distill(affected, options)
        write_run_report(failed, contents.size)
        return if contents.empty? && failed.empty?

        puts "\n#{Rainbow("#{contents.size} principle(s) updated.").green}"

        # Publish before checking failures so a failed principle doesn't discard successful ones.
        publish(contents, affected, push: options[:push], failed: failed) if contents.any?

        abort_on_failures(failed)
      end

      # Writes go straight to the working tree. In --push mode disk writes are deferred (see build_distilled_contents)
      # until after the publish branch is checked out, so the resulting MR diff contains ONLY the distilled files.
      def distill_and_write_principles(affected, rewrite: false)
        results, failed = build_distilled_contents(affected, rewrite: rewrite)
        results.each do |name, content|
          path = manifest.principles_path(name)
          File.write(Workspace.safe_join(path), content)
          puts "  #{name}: #{Rainbow("updated and written to #{path}").green}"
        end

        [results, failed]
      end

      # Read-only guard for the Duo Code Review instruction fences in .gitlab/duo/mr-review-instructions.yaml. Loads the
      # manifest (for sources/filters) but performs no distillation or writes.
      #
      # A freshly seeded fence (manifest entry present, distilled file pending) only warns: seeding a fence before its
      # first distillation is the documented flow, so it must not fail the pipeline.
      # Malformed and orphaned fences always fail the guard (exit 1) so real, ref-fixable breakage cannot land silently.
      # The failure message is self-service: it names the exact fix per category and links the developer docs, because
      # this job also runs on doc/**/*.md changes and can surface to authors who never touched a fence.
      #
      # `warn_stale` downgrades STALE drift to a non-blocking warning (exit 0).
      # Since fence regeneration is decoupled from distillation (a team's distilled MR merges independently and the
      # daily fence-reconcile job catches the fence up from merged master afterwards), fence staleness is expected
      # transient state on ordinary MRs and on master, not something those refs can fix.
      # On the owned-path/reconcile refs the flag is left off, so staleness there still blocks.
      # Malformed and orphaned fences fail regardless of the flag.
      def check_duo_instructions_fences(warn_stale: false)
        manifest.load
        result = manifest.problematic_duo_review_instructions

        result.pending.each do |principle|
          warn Rainbow("Duo review instruction fence '#{principle}' is seeded but not yet " \
            'distilled; the next principles sync will populate it. No action needed.').yellow
        end

        blocking = warn_stale ? (result.malformed + result.orphaned).uniq : result.failing

        if blocking.empty?
          warn_stale_fences(result.stale) if warn_stale && result.stale.any?
          puts Rainbow('Duo review instruction fences are up to date.').green
          return
        end

        report_failing_fences(result, warn_stale: warn_stale)
        # rubocop:disable Rails/Exit -- standalone CLI uses the process status to signal guard failure to the shell
        exit 1
        # rubocop:enable Rails/Exit
      end

      # Prints the stale fences as a non-blocking warning (used under --warn-stale, where staleness does not fail the
      # guard).
      # The daily fence-reconcile job projects these onto master; nothing on the current ref needs to act.
      def warn_stale_fences(stale)
        warn Rainbow("Duo review instruction fences are stale on this ref: #{stale.join(', ')}.").yellow
        warn '  This is expected between a distilled MR merging and the daily fence-reconcile'
        warn '  job catching the fences up from master. No action needed on this ref.'
      end

      # Prints per-category guidance for the fences that fail the guard, so the author knows exactly what to do rather
      # than seeing a bare principle list.
      #
      # Under `warn_stale` the stale category is non-blocking, so it is surfaced as a warning (via warn_stale_fences)
      # rather than a blocking failure and is omitted from the per-category failure guidance here.
      def report_failing_fences(result, warn_stale: false)
        warn_stale_fences(result.stale) if warn_stale && result.stale.any?

        warn Rainbow('Duo review instruction fences need attention ' \
          "(#{DuoInstructions::DUO_PATH}):").red

        if result.stale.any? && !warn_stale
          warn Rainbow("  Stale: #{result.stale.join(', ')}").red
          warn '    The distilled file changed after the fence was generated. Regenerate the'
          warn '    fences by running the principles sync from the repo root:'
          warn Rainbow('      scripts/lint-duo-review-instructions.sh   # to re-check').faint
          warn '    then commit the updated file. If you did not mean to change these fences'
          warn "    (for example, you only edited docs), revert your change to #{DuoInstructions::DUO_PATH}."
        end

        if result.malformed.any?
          warn Rainbow("  Malformed: #{result.malformed.join(', ')}").red
          warn '    A BEGIN marker has no matching END, or a key is duplicated. Fix the'
          warn '    markers so each fence is exactly one BEGIN/END pair, or remove the fence.'
        end

        if result.orphaned.any?
          warn Rainbow("  Orphaned: #{result.orphaned.join(', ')}").red
          warn '    The fence has no manifest entry and no distilled file, so it has no source'
          warn '    of truth. Remove the fence, or add the matching principle to'
          warn '    .ai/principles/manifest.yml if the fence should stay.'
        end

        warn "See #{DUO_INSTRUCTIONS_DOC} for how these fences are generated and kept in sync."
      end

      # Reconciles the Duo Code Review instruction fences from the committed (master) distilled files by pure
      # projection: it regenerates each fence's directives and body from the on-disk distilled file's frontmatter and
      # checklist, and NEVER re-runs distillation.
      # This is what keeps the reconcile idempotent and its own MR guard-green: a fence only changes when the distilled
      # file it mirrors already changed on master.
      #
      # Decoupled from the distillation --push path (which no longer touches the fences at all): a team MR merges its
      # distilled file independently, and this scheduled job catches the fence up from merged master afterwards.
      # Because the projection reads the same ref the reconcile MR targets (the branch is cut from
      # origin/<default_branch> and the fences are projected afterwards, inside create_reconcile_mr_from_working_tree),
      # a team MR merging mid-run does not reopen a stale window.
      #
      # Without --push it only rewrites the file on disk from the current working tree (local/dry use). With --push the
      # on-disk projection is deferred to the freshly cut branch, so it is skipped here.
      def reconcile_duo_instructions_fences(push: false)
        banner("Loading manifest from #{Manifest::MANIFEST_PATH}...")
        manifest.load

        unless push
          banner("\nReconciling Duo Code Review instruction fences from committed distilled files...")
          changed = manifest.generate_duo_review_instructions

          unless changed
            puts "\n#{Rainbow('Duo review instruction fences are already up to date.').green}"
            return
          end

          puts "\n#{Rainbow('[LOCAL]').cyan} Fences reconciled on disk. Pass --push to open a reconcile MR."
          return
        end

        banner("\nReconciling Duo Code Review instruction fences on a fresh branch from master...")
        create_reconcile_mr_from_working_tree(manifest.auto_mr_config, manifest)
      end

      # Stage 1 of the split pipeline: scan for drift and emit the child pipeline that will distill each affected
      # principle in its own job.
      #
      # This job triggers no distillation, so it is fast and cheap; the expensive, timeout-prone work all happens in the
      # generated jobs, each with its own timeout.
      # That is the whole point of the split: a single slow or retrying principle can no longer consume a budget shared
      # with every other principle (see gitlab-org/gitlab#607365).
      #
      # `validate_config!` runs here rather than only in the distill jobs so a misconfigured Workflow API fails once,
      # immediately, instead of N times in parallel after the runners have already spun up.
      def generate_child_pipeline(options)
        workflow.validate_config!

        banner("Loading manifest from #{Manifest::MANIFEST_PATH}...")
        manifest.load

        banner("\nScanning principles for stale SSOT sources...")
        affected = manifest.affected_principles(force: options[:force], only: options[:only])

        if affected.empty?
          puts "\n#{Rainbow('All principles are up to date.').green}"
        else
          puts "\n#{Rainbow("Affected principles: #{affected.keys.join(', ')}").yellow}"
        end

        write_child_pipeline(affected.keys)
      end

      # Stage 2, one CI job per principle: distill exactly this principle and record the outcome as an artifact.
      # Publishes nothing: the fan-in in `collect` owns publishing, because building the per-team MRs shares a single
      # working tree and cannot be parallelized the same way.
      #
      # A principle absent from the manifest is a hard error: it means the generated pipeline and the manifest have
      # diverged, and silently succeeding would let the collect job report the principle as "never ran" and quietly skip
      # it every week.
      def distill_one(name)
        banner("Loading manifest from #{Manifest::MANIFEST_PATH}...")
        manifest.load

        config = manifest.principle_config(name)
        abort Rainbow("ERROR: unknown principle '#{name}' (not in #{Manifest::MANIFEST_PATH})").red unless config

        workflow.validate_config!

        banner("\nDistilling #{name}...")
        affected = {
          name => {
            config: config,
            prior_sha: manifest.prior_distillation_sha(name),
            new_sources: manifest.new_sources_for(name, config)
          }
        }
        contents, failed = build_distilled_contents(affected)

        record_distill_artifact(name, contents[name], failed)
      end

      # Stage 3, the fan-in: reconstruct the run from the distill jobs' artifacts and publish. This is the only stage
      # that touches git, so the `git checkout -B` per team in `create_branch_and_mr` still operates on one working
      # tree, unchanged.
      def collect(expected, push: false)
        workflow.validate_publish_config! if push

        banner("Loading manifest from #{Manifest::MANIFEST_PATH}...")
        manifest.load

        banner("\nCollecting distilled principles from #{expected.size} distill job(s)...")
        result = artifacts.collect(expected)

        report_collected(result)
        write_run_report(result.failed, result.contents.size, not_run: result.not_run)

        # `affected` is rebuilt here (rather than carried through artifacts) because the MR description needs each
        # principle's prior_sha and changed_sources, and those come from the same manifest scan the generator already
        # ran against the same commit.
        affected = manifest.affected_principles(only: expected)

        if result.contents.any?
          puts "\n#{Rainbow("#{result.contents.size} principle(s) updated.").green}"
          publish(result.contents, affected, push: push, failed: result.failed, not_run: result.not_run)
        end

        # `not_run` is deliberately NOT fatal: a principle whose job never completed has not been shown to be
        # undistillable, and its checksum is untouched, so the next scheduled run simply re-attempts it.
        # Only a genuine post-retry failure exits non-zero.
        abort_on_failures(result.failed)
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

      def artifacts
        @artifacts ||= Artifacts.new(Workspace.safe_join(ARTIFACTS_DIR))
      end

      def write_child_pipeline(names)
        path = Workspace.safe_join(CHILD_PIPELINE_PATH)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, ChildPipeline.new(names).to_yaml)

        puts "\n#{Rainbow("Wrote a child pipeline with #{names.size} distill job(s) to " \
          "#{CHILD_PIPELINE_PATH}.").green}"
      end

      # Maps the three outcomes of a single-principle distillation onto the artifact contract.
      # `unchanged` is distinct from `failed`: the workflow ran cleanly and produced no meaningful diff, which is a
      # normal, healthy result and must not reach the Slack alert.
      def record_distill_artifact(name, content, failed)
        if failed.include?(name)
          artifacts.write(name, Artifacts::STATUS_FAILED)
          abort "\n#{Rainbow("ERROR: #{name} failed distillation after retries").red}"
        end

        if content.nil?
          artifacts.write(name, Artifacts::STATUS_UNCHANGED)
          puts "\n#{Rainbow("#{name}: no meaningful changes.").faint}"
          return
        end

        artifacts.write(name, Artifacts::STATUS_UPDATED, content: content)
        puts "\n#{Rainbow("#{name}: distilled.").green}"
      end

      # Surfaces the two abnormal outcomes with distinct wording, so an operator reading the collect job's log can tell
      # a principle that Duo could not distill from one whose job never got to run.
      def report_collected(result)
        if result.failed.any?
          warn Rainbow("  #{result.failed.size} principle(s) failed distillation after retries: " \
            "#{result.failed.join(', ')}").red
        end

        return if result.not_run.empty?

        warn Rainbow("  #{result.not_run.size} principle(s) produced no result because their distill " \
          "job did not complete: #{result.not_run.join(', ')}").yellow
        warn '  This is not a distillation failure - their checksums are untouched, so the next'
        warn '  scheduled run re-attempts them.'
      end

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

      # Runs after publish (see #run) so a distillation failure still exits non-zero without discarding principles that
      # succeeded.
      def abort_on_failures(failed)
        return if failed.empty?

        abort "\n#{Rainbow("ERROR: #{failed.size} principle(s) failed after retries: #{failed.join(', ')}").red}"
      end

      # Emits the dotenv report read by the `ai-principles-report-failure` Slack job.
      # Written on every run that reaches distillation, including clean ones: the artifact is declared unconditionally
      # in CI, so skipping the write would log `no matching files` / `No files to upload` on each green weekly run.
      # `AI_PRINCIPLES_FAILED_NAMES` is empty on a clean run, which is what the Slack job tests to pick its wording.
      #
      # `not_run` gets its own vars rather than overloading the failure ones, so the Slack job can word "Duo could not
      # distill these" and "these jobs never ran" differently.
      # It is empty in the single-job path, where there are no per-principle jobs that could go missing.
      #
      # Best-effort: a write failure must not mask a distillation failure the caller may be about to abort on.
      def write_run_report(failed, published_count, not_run: [])
        path = Workspace.safe_join(RUN_REPORT_PATH)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, <<~ENV_FILE)
          AI_PRINCIPLES_FAILED_COUNT=#{failed.size}
          AI_PRINCIPLES_FAILED_NAMES=#{failed.join(', ')}
          AI_PRINCIPLES_PUBLISHED_COUNT=#{published_count}
          AI_PRINCIPLES_NOT_RUN_COUNT=#{not_run.size}
          AI_PRINCIPLES_NOT_RUN_NAMES=#{not_run.join(', ')}
        ENV_FILE
      rescue StandardError => e
        warn Rainbow("  WARNING: could not write #{RUN_REPORT_PATH} (#{e.message}); " \
          'the Slack alert will fall back to a generic message').yellow
      end

      def publish(contents, affected, push:, failed: [], not_run: nil)
        unless push
          puts "\n#{Rainbow('[LOCAL]').cyan} Distillation complete. Pass --push to create a branch and MR."
          return
        end

        options = { failed: failed }
        options[:not_run] = not_run if not_run
        create_branch_and_mr(contents, affected, manifest.auto_mr_config, **options)
      end

      def banner(message)
        puts Rainbow(message).bold
      end

      # The AGENTS.md/CLAUDE.md/SKILL.md/CODEOWNERS generators are manifest-driven (they do not read distilled bodies),
      # so they can be regenerated straight from the manifest here.
      #
      # The Duo Code Review fences are deliberately NOT regenerated in this path: they are reconciled from merged-master
      # content by the separate scheduled reconcile job (see #reconcile_duo_instructions_fences), so a team's distilled
      # MR and the fence update are independently mergeable and a retried, non-deterministic distillation can never
      # leave the fences out of sync with what actually ships.
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

      # Returns [{principle_name => fully_assembled_file_content}, [failed_names]] without writing to disk, so --push
      # mode can defer writes until after the publish branch is checked out off origin/master.
      def build_distilled_contents(affected, rewrite: false)
        header = '<!-- Auto-generated from docs.gitlab.com by ' \
          "gitlab-ai-principles-distiller — do not edit manually -->\n\n"

        run = DistillationRun.new(affected: affected, target_sha: distillation_base_sha)
        workflow.validate_commit_shas!([run.target_sha, *run.affected.values.filter_map { |info| info[:prior_sha] }])
        results = parallel_distill(run, rewrite: rewrite)

        failed = []
        contents = {}

        run.affected.each_key do |name|
          current, updated = results[name]

          if updated.nil?
            failed << name
            next
          end

          config = manifest.principle_config(name)

          updated = Diff.reduce_noise(current, updated, source_text: principle_source_text(config)) if current

          # Assemble the full body (header + prerequisite note + sources footer) BEFORE the meaningful? gate.
          # `current` is read from disk with its footer intact (strip_frontmatter removes only the YAML), so comparing
          # the raw checklist against it always looked "meaningful" and produced frontmatter-only MRs.
          # Comparing the fully-assembled body against `current` makes the gate symmetric.
          assembled = assemble_distilled_body(updated, config, name, header)

          unless Diff.meaningful?(current, assembled)
            puts "  #{name}: #{Rainbow('no meaningful changes').faint}"
            next
          end

          checksum = manifest.compute_checksum(config)
          contents[name] = <<~CONTENT
        ---
        source_checksum: #{checksum}
        distilled_at_sha: #{run.target_sha}
        ---
        #{assembled}
          CONTENT
        end

        [contents, failed]
      end

      # Concatenate SSOT sources and the baseline for inline-code verification.
      def principle_source_text(config)
        text = manifest.config_source_paths(config)
          .filter_map { |path| manifest.read_repo_file(path) }
          .join("\n")

        text unless text.empty?
      end

      # Build the complete body so Diff.meaningful? compares symmetric inputs.
      def assemble_distilled_body(updated, config, name, header)
        note = manifest.prerequisite_note(name)

        updated = absolutize_links(updated, config, name)
        updated = "#{header}#{updated}" unless updated.start_with?('<!-- Auto-generated')
        updated = updated.sub(/^(<!-- Auto-generated.*-->)\n\n*/, "\\1\n\n#{note}") if note
        "#{updated.rstrip}\n\n#{manifest.sources_footer(config)}"
      end

      # Rewrites source-relative Markdown links to absolute docs.gitlab.com URLs.
      # The agent copies links verbatim from the SSOT docs, where they resolve correctly; from
      # `.ai/principles/distilled/` the relative base differs, so we resolve each link against its source directory and
      # emit the canonical published URL instead.
      # Unresolved relatives are left intact and logged.
      def absolutize_links(updated, config, name)
        exist = ->(repo_path) { File.exist?(Workspace.safe_join(repo_path)) }
        warn_unresolved = ->(rel_path) do
          warn Rainbow("  WARNING: #{name}: could not absolutize relative link #{rel_path}").yellow
        end

        Links.absolutize(
          updated,
          sources: config.fetch('sources', []),
          exist: exist,
          warn_unresolved: warn_unresolved
        )
      end

      # `mutex` serialises log output and writes to `results`.
      # Manifest#read_repo_file owns its own mutex for the SSOT file cache.
      # Manifest must be loaded before forking; otherwise the unsynchronized
      # `@data ||= load` in Manifest#data would race.
      def parallel_distill(run, rewrite: false)
        raise 'manifest must be loaded before parallel_distill' unless manifest.loaded?

        mutex = Mutex.new
        results = {}

        run.affected.each_slice(MAX_CONCURRENT_DISTILLATIONS) do |batch|
          threads = batch.map do |name, info|
            Thread.new do
              current = read_principles_file(name)
              updated = distill_principle(name, info[:config], prior_sha: info[:prior_sha], target_sha: run.target_sha,
                new_sources: info[:new_sources] || [], mutex: mutex, rewrite: rewrite)
              mutex.synchronize { results[name] = [current, updated] }
            end
          end
          threads.each(&:join)
        end

        results
      end

      def distill_principle(name, config, prior_sha:, target_sha:, new_sources: [], mutex: nil, rewrite: false)
        log = ->(msg) { mutex ? mutex.synchronize { puts msg } : puts(msg) }
        log_warn = ->(msg) { mutex ? mutex.synchronize { warn msg } : warn(msg) }

        announce_distillation_start(name, mutex)
        workflow.validate_sources!(config) # raises if any SSOT source is missing on disk
        workflow.warn_if_sources_differ_from_pushed_branch(config, log_warn: log_warn)

        log_warn.call(Rainbow("  WARNING: --rewrite is a no-op with the Workflow API backend").yellow) if rewrite

        updated = nil
        prior_failure_was_drift = false
        DISTILL_MAX_RETRIES.times do |attempt|
          if attempt.positive?
            backoff = retry_backoff(attempt, deterministic: prior_failure_was_drift)
            log.call(Rainbow("  Waiting #{backoff}s before retry #{attempt} for #{name}...").faint)
            workflow.sleep_with_heartbeat(backoff, "retry #{attempt} for #{name}", log)
          end

          log.call("  Triggering Duo Workflow for #{name}#{" (retry #{attempt})" if attempt.positive?}...")
          result = workflow.distill(name, config, prior_sha: prior_sha, target_sha: target_sha,
            new_sources: new_sources)

          if result&.include?('## Checklist')
            baseline_missing = baseline_drift(config, result)

            if baseline_missing.empty?
              updated = result
              break
            end

            warn_baseline_drift(name, baseline_missing, attempt, log_warn)
            prior_failure_was_drift = true
            next
          end

          prior_failure_was_drift = false

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

        repair_escape_artifacts(Diff.strip_preamble(updated), config, log_warn)
      end

      # Preserve literal escape artifacts copied from the SSOT while correcting entities and escaped quotes or brackets
      # that appear only in output from the distillation workflow.
      # Backslash-escaped backticks remain untouched because they delimit nested inline-code spans.
      def repair_escape_artifacts(content, config, log_warn)
        in_fence = false
        repaired_lines = []
        source_lines = manifest.config_source_paths(config)
          .filter_map { |path| manifest.read_repo_file(path) }
          .flat_map(&:lines)
          .map { |line| normalize_escape_artifact_line(line) }

        repaired = content.lines.map.with_index do |line, index|
          if line.match?(/^[ \t]*(?:`{3,}|~{3,})/)
            in_fence = !in_fence
            next line
          end

          next line if in_fence
          next line if source_lines.include?(normalize_escape_artifact_line(line))

          unescaped = line.gsub(/&(lt|gt|amp|quot|#39);/) do
            { 'lt' => '<', 'gt' => '>', 'amp' => '&', 'quot' => '"', '#39' => "'" }.fetch(Regexp.last_match(1))
          end
          unescaped = unescaped.gsub(/\\(["'<>])/, '\\1')

          repaired_lines << (index + 1) if unescaped != line
          unescaped
        end

        if repaired_lines.any?
          log_warn.call("  WARNING: repaired escape artifacts on line(s) #{repaired_lines.join(', ')}")
        end

        repaired.join
      end

      def normalize_escape_artifact_line(line)
        line.strip.sub(/\A[-*+]\s+/, '')
      end

      # Chooses the pre-retry backoff. A deterministic failure (baseline drift on the prior attempt) uses a short fixed
      # wait since the retry re-runs identical input; every other failure (transient fetch, agent crash, invalid
      # content) uses the long Gitaly-oriented backoff, which gives an overloaded node time to recover.
      # `attempt` is 1-based for the backoff schedule (attempt 0 never waits).
      def retry_backoff(attempt, deterministic:)
        return DISTILL_BASELINE_DRIFT_BACKOFF_SECONDS if deterministic

        DISTILL_RETRY_BACKOFF_SECONDS[attempt - 1]
      end

      # Mechanical guard for distillation prompt rule 15: baseline rules must be included verbatim. Prompt-only
      # enforcement proved insufficient: a re-distillation relocated and corrupted a baseline section (duplicated
      # sentence fragment, broken sub-bullet) despite the verbatim instruction, so drift here fails the attempt and
      # triggers a retry instead of publishing corrupted baseline rules.
      #
      # The comparison operates on normalized logical units (one unit per bullet or paragraph, hard-wrapped continuation
      # lines joined, inner whitespace collapsed), NOT on physical lines: the agent routinely re-flows long lines, and a
      # pure re-wrap of identical text is not corruption.
      # A line-level check rejected such reflows deterministically, burning every retry on byte-identical text.
      # Heading lines and blank lines are unit boundaries and exempt, because the agent may adapt heading levels and
      # placement when integrating baseline rules into an existing subsection.
      #
      # Both sides of the comparison are scoped, not raw:
      # - `baseline_rules` drops any preamble before the baseline's own `## Checklist` heading (title, prerequisite
      #   blockquote, framing prose, a `---` divider).
      #   That preamble is document scaffolding, not a rule, and `Workflow#build_goal` explicitly instructs the agent to
      #   emit "ONLY the checklist content" - comparing the full baseline demanded text the prompt forbids producing, an
      #   unsatisfiable guard (observed with testing-frontend-testing-hierarchy, job 15601793108).
      #   Most baselines have no `## Checklist` heading, so this is a no-op for them.
      # - `checklist_body` drops the `## Authoritative sources` footer that `assemble_distilled_body` appends after this
      #   guard normally runs.
      #   `content` here is the raw agent output, but the guard must still tolerate a footer if the agent emits one
      #   anyway: a baseline path that is also `sources:`-listed legitimately appears twice otherwise, tripping the
      #   exactly-once check on the tool's own output (observed with documentation-topics).
      #
      # Returns the baseline units that are altered, missing, or duplicated in `content` (empty when clean, when the
      # principle has no baseline, or when the baseline file is unreadable).
      # Duplication matters because the observed corruption emitted a baseline fragment twice: every baseline rule must
      # appear exactly once.
      def baseline_drift(config, content)
        baseline_path = config['baseline']
        return [] unless baseline_path

        baseline = manifest.read_repo_file(baseline_path)
        return [] unless baseline

        occurrences = logical_units(checklist_body(content)).tally
        logical_units(baseline_rules(baseline)).reject { |unit| occurrences[unit] == 1 }
      end

      # Returns the rule-bearing portion of a baseline file: everything from its own `## Checklist` heading onward, or
      # the whole file when no such heading exists (most baselines have none - they are already pure rule content with
      # no title/prerequisite preamble).
      def baseline_rules(baseline)
        heading = baseline.index(/^##\s+Checklist\s*$/)
        heading ? baseline[heading..] : baseline
      end

      # Returns `content` truncated before the `## Authoritative sources` footer, so a footer-listed path cannot be
      # counted as a duplicate of the same path appearing in the checklist body.
      def checklist_body(content)
        content.split(/^##\s+Authoritative sources\s*$/, 2).first
      end

      # Splits markdown into logical units: each list item or paragraph is one unit, with hard-wrapped continuation
      # lines joined and inner whitespace collapsed.
      # Heading lines and blank lines terminate the current unit and are excluded from the result.
      #
      # The leading list marker (-, *, +, or an ordered "1." / "1)") is stripped during normalization so a rule's
      # identity is its TEXT, not its bullet-vs-paragraph presentation.
      # A baseline may store a rule as a bare paragraph (e.g. an intro sentence ending in "For example:" that precedes
      # nested sub-bullets), while every reasonable distillation renders that same rule as a bullet so the sub-bullets
      # attach - a legitimate reformat, not corruption. Keeping the marker in the unit made those two forms compare
      # unequal, so the guard flagged drift on byte-identical rule text and burned every retry (observed with the
      # database-fundamentals baseline).
      # Rewording, omission, and duplication still change the text itself and remain detected.
      #
      # A single trailing period is likewise stripped: the agent routinely appends one while rephrasing a baseline rule
      # into a sentence, and that punctuation is presentation, not the rule's identity (observed across several
      # baselines whose committed distilled form differs from the baseline only by a trailing ".").
      # A reworded or truncated rule still differs by more than punctuation and remains detected.
      def logical_units(text)
        units = []
        current = nil

        text.each_line do |raw|
          line = raw.strip

          if line.empty? || line.start_with?('#') || line.match?(THEMATIC_BREAK)
            units << current if current
            current = nil
          elsif current.nil? || line.match?(/\A(?:[-*+]|\d+[.)])\s/)
            units << current if current
            current = line
          else
            current = "#{current} #{line}"
          end
        end

        units << current if current
        units.map { |unit| unit.sub(/\A(?:[-*+]|\d+[.)])\s+/, '').gsub(/\s+/, ' ').delete_suffix('.') }
      end

      def warn_baseline_drift(name, drifted, attempt, log_warn)
        msg = "  WARNING: Duo altered, omitted, or duplicated #{drifted.size} baseline rule(s) " \
          "for #{name} (attempt #{attempt + 1}/#{DISTILL_MAX_RETRIES})"
        log_warn.call(Rainbow(msg).yellow)
        drifted.first(3).each { |unit| log_warn.call(Rainbow("    drifted: #{unit}").faint) }
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
