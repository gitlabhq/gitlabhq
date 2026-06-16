# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Manifest loading, validation, frontmatter handling, affected-principle
      # detection, AGENTS.md / SKILL.md generation, and prerequisite-note
      # injection. Owns the SSOT file_cache.
      #
      # `@data` is not synchronized; callers must load before forking (see
      # `Sync#parallel_distill`'s assertion).
      class Manifest
        MANIFEST_PATH = '.ai/principles/manifest.yml'
        PRINCIPLES_DIR = '.ai/principles/distilled'
        CLAUDE_SKILL_DIR = '.claude/skills/gitlab-coding-principles'
        CLAUDE_SKILL_PATH = "#{CLAUDE_SKILL_DIR}/SKILL.md".freeze
        AGENTS_SKILL_PATH = '.agents/skills/gitlab-coding-principles/SKILL.md'
        CODEOWNERS_PATH = '.gitlab/CODEOWNERS'

        # Markers delimiting the gem-managed per-file CODEOWNERS block. The
        # block is inserted right after the broad `/.ai/` rule so that, by
        # CODEOWNERS last-match-wins, each distilled file routes approval to
        # its SSOT-owning team rather than the broad AI-harness owners.
        CODEOWNERS_BEGIN = '# BEGIN GENERATED: gitlab-ai-principles-distiller — do not edit manually'
        CODEOWNERS_END = '# END GENERATED: gitlab-ai-principles-distiller'

        # The broad rule the generated block must follow (and override per
        # file). Kept in sync with .gitlab/CODEOWNERS.
        CODEOWNERS_AI_RULE = %r{^/\.ai/ .+$}

        # Global, cross-cutting files regenerated from the manifest on every
        # run. They embed the full routing table for ALL principles, so SSOT
        # teams have no stake in their content; the per-team MR fan-out routes
        # them to a separate "tooling" MR (see Sync::AutoMr).
        TOOLING_PATHS = [
          'AGENTS.md',
          'CLAUDE.md',
          AGENTS_SKILL_PATH,
          CLAUDE_SKILL_PATH,
          CODEOWNERS_PATH
        ].freeze

        AUTO_MR_REQUIRED_KEYS = %w[branch_prefix title_template labels remove_source_branch].freeze

        def initialize
          @file_cache = {}
          @file_cache_mutex = Mutex.new
        end

        attr_reader :file_cache

        # The parsed YAML hash. The writer is a public test seam: specs
        # can inject fixtures without a manifest.yml on disk, bypassing
        # validate_principles!. Production code only reaches `data` via
        # `load`, where validation runs.
        attr_writer :data

        def data
          @data ||= load
        end

        def loaded?
          !@data.nil?
        end

        def load
          path = Workspace.safe_join(MANIFEST_PATH)
          abort Rainbow("ERROR: Manifest not found at #{path}").red unless File.exist?(path)

          @data = YAML.safe_load_file(path)
          validate_principles!
          @data
        end

        def principles
          data.fetch('principles', {})
        end

        def static_entries
          data.fetch('static_entries', [])
        end

        def principle_config(name)
          principles[name]
        end

        # No hardcoded fallbacks: missing keys fail fast rather than
        # masking misconfig with stale defaults.
        def auto_mr_config
          cfg = data['auto_mr']
          abort Rainbow("ERROR: manifest.yml is missing the `auto_mr:` block").red unless cfg.is_a?(Hash)

          missing = AUTO_MR_REQUIRED_KEYS - cfg.keys
          abort Rainbow("ERROR: manifest.yml `auto_mr:` is missing keys: #{missing.join(', ')}").red if missing.any?

          cfg
        end

        def principles_path(name)
          File.join(PRINCIPLES_DIR, principles_filename(name))
        end

        # The SSOT-owning CODEOWNERS team handle(s) for a principle. This is
        # the axis the auto-MR fan-out groups by, so each per-team MR touches
        # only files that team owns and CODEOWNERS routes the approval to the
        # right reviewers. Required for every principle (see
        # validate_principles!), so no fallback here.
        def principle_owner_team(name)
          principle_config(name)&.dig('owner_team')
        end

        # Additional teams to mention ("request a review from") in the MR
        # description for cross-team SSOT docs. The primary owner_team gets the
        # MR via CODEOWNERS; secondary teams are notified but not required.
        def principle_secondary_teams(name)
          Array(principle_config(name)&.dig('secondary_teams'))
        end

        # The team-grouping key for a principle: its owner_team handle. Used by
        # the auto-MR fan-out and per-team branch naming.
        def principle_team(name)
          principle_owner_team(name) || 'Other'
        end

        # URL/branch-safe slug for the per-team branch suffix. Prefers the
        # principle's explicit `team_slug`; otherwise derives it from the
        # owner_team handle's last path segment (e.g.
        # "@gitlab-org/maintainers/database" -> "database"). An explicit slug
        # is needed where the last segment is generic and would collide across
        # teams (e.g. ".../authentication/approvers" and
        # ".../authorization/approvers" both end in "approvers").
        #
        # Accepts either a principle name or an owner_team handle (the fan-out
        # grouping key). Resolution order:
        #   1. explicit `team_slug` on the principle (when given a name), or on
        #      any principle owned by the handle (when given a handle);
        #   2. derived from the handle's last path segment.
        def team_slug(team_or_name)
          explicit = principle_config(team_or_name)&.dig('team_slug') ||
            explicit_slug_for_handle(team_or_name)
          return slugify(explicit) if explicit

          handle = principle_owner_team(team_or_name) || team_or_name
          slugify(last_handle_segment(handle))
        end

        # Groups the given principle names by owner_team handle, preserving the
        # manifest's declaration order for both teams and members.
        def group_principles_by_team(names)
          ordered = principles.keys & names.to_a
          ordered.each_with_object({}) do |name, by_team|
            (by_team[principle_team(name)] ||= []) << name
          end
        end

        def build_diff_hint(sha, source_paths)
          ['git', 'diff', "#{sha[0, 12]}..HEAD", '--', *source_paths].shelljoin
        end

        def load_frontmatter_data
          Dir.glob(Workspace.safe_join(PRINCIPLES_DIR, '*.md')).each_with_object({}) do |path, data|
            name = File.basename(path, '.md')
            frontmatter = extract_frontmatter(File.read(path))
            next unless frontmatter&.key?('source_checksum')

            data[name] = {
              checksum: frontmatter['source_checksum'],
              distilled_at_sha: frontmatter['distilled_at_sha']
            }
          end
        end

        def extract_frontmatter(content)
          return unless content.start_with?("---\n")

          _empty, frontmatter, _rest = content.split("---\n", 3)
          YAML.safe_load(frontmatter) if frontmatter
        end

        def strip_frontmatter(content)
          return content unless content.start_with?("---\n")

          parts = content.split("---\n", 3)
          parts.size == 3 ? parts[2].lstrip : content
        end

        def compute_checksum(config)
          sources = config.fetch('sources', [])
          digest = OpenSSL::Digest.new('SHA256')

          # Hash routing-relevant fields so changes to description, group,
          # prerequisite, or file_filters invalidate the checksum.
          # `to_json` keeps the encoding canonical across YAML quote-style
          # round-trips while preserving the nil/""/false distinction.
          %w[description group prerequisite].each do |key|
            digest.update("#{key}=#{config[key].to_json}")
          end
          Array(config['file_filters']).each { |filter| digest.update(filter) }

          baseline_path = config['baseline']
          if baseline_path
            digest.update(baseline_path)
            baseline_content = read_repo_file(baseline_path)
            digest.update(baseline_content) if baseline_content
          end

          sources.each do |source|
            digest.update(source['path'])
            content = read_repo_file(source['path'])
            digest.update(content) if content
          end

          # 16 hex chars: collision-free for ~25 principles, short enough
          # to skim in MR diffs.
          digest.hexdigest[0, 16]
        end

        def affected_principles(force: false, only: nil)
          frontmatter_data = load_frontmatter_data

          principles.each_with_object({}) do |(name, config), affected|
            if only && !only.include?(name) # -- standalone script without Rails
              puts "  ⏭️  #{name}: #{Rainbow('skipped (not in --only list)').faint}"
              next
            end

            current_checksum = compute_checksum(config)
            stored = frontmatter_data[name]
            stored_checksum = stored&.dig(:checksum)

            if !force && current_checksum == stored_checksum
              puts "  ✅ #{name}: #{Rainbow('up to date').green}"
            else
              sources = config.fetch('sources', [])
              distilled_at_sha = stored&.dig(:distilled_at_sha)
              affected[name] = {
                config: config,
                changed_sources: sources,
                prior_sha: distilled_at_sha
              }

              reason = if force
                         'forced'
                       else
                         (stored_checksum ? 'sources or docs changed' : 'no previous checksum')
                       end

              puts "  🔄 #{name}: #{Rainbow('needs update').yellow} (#{reason})"

              if distilled_at_sha
                source_paths = sources.map { |s| s['path'] }
                baseline_path = config['baseline']
                source_paths.unshift(baseline_path) if baseline_path
                diff_cmd = build_diff_hint(distilled_at_sha, source_paths)
                puts "     🔍 To see what changed: #{Rainbow(diff_cmd).cyan}"
              end
            end
          end
        end

        def read_repo_file(path)
          # Guard file_cache writes from concurrent parallel_distill threads.
          @file_cache_mutex.synchronize do
            file_cache[path] ||= begin
              # `path` originates from the manifest YAML; `safe_join` rejects
              # traversal segments that would escape the workspace. Same
              # guarantee applies to the other `Workspace.safe_join` callsites
              # in this gem.
              full_path = Workspace.safe_join(path)
              if File.exist?(full_path)
                File.read(full_path)
              else
                dir = full_path.sub(%r{(\.md|/)$}, '')
                idx_path = File.join(dir, '_index.md')
                File.read(idx_path) if File.exist?(idx_path)
              end
            end
          end
        end

        def sources_footer(config)
          sources = config.fetch('sources', [])
          return '' if sources.empty?

          lines = sources.map { |s| "- #{s['path']}" }.join("\n")
          <<~FOOTER
            ## Authoritative sources

            For the full picture, see:

            #{lines}
          FOOTER
        end

        # Writes the gitlab-coding-principles SKILL.md to both .agents/
        # (OpenCode) and .claude/ (Claude Code).
        def generate_principles_skill
          routing_table = build_skill_routing_table

          skill_content = <<~SKILL
            ---
            name: gitlab-coding-principles
            description: Load all relevant GitLab development principles before planning or implementing. Evaluates every principle group to ensure cross-domain coverage.
            ---

            # Load Project Principles

            #{routing_table.rstrip}
          SKILL

          written = []
          [
            Workspace.safe_join(AGENTS_SKILL_PATH),
            Workspace.safe_join(CLAUDE_SKILL_PATH)
          ].each do |path|
            next if File.exist?(path) && File.read(path) == skill_content

            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, skill_content)
            written << path.delete_prefix("#{Workspace.path}/")
          end

          if written.any?
            puts "  Written skill to: #{written.join(', ')}"
          else
            puts Rainbow('  Skill already up to date').faint
          end
        end

        # Refreshes the generated OpenCode-context section in AGENTS.md (and
        # copies the result to CLAUDE.md for parity).
        def generate_agents_md_context_loading
          routing_table = build_skill_routing_table

          generated_header = '<!-- BEGIN GENERATED: gitlab-ai-principles-distiller — do not edit manually -->'
          generated_footer = '<!-- END GENERATED -->'

          opencode_section = [
            generated_header,
            '### OpenCode',
            '',
            routing_table.rstrip,
            generated_footer
          ].join("\n")

          agents_path = Workspace.safe_join('AGENTS.md')
          return unless File.exist?(agents_path)

          content = File.read(agents_path)

          updated = content.sub(
            /#{Regexp.escape(generated_header)}\n.*?#{Regexp.escape(generated_footer)}/m,
            opencode_section
          )

          return if updated == content

          File.write(agents_path, updated)

          claude_path = Workspace.safe_join('CLAUDE.md')
          File.write(claude_path, updated)

          puts "  Updated AGENTS.md and CLAUDE.md (#{principles.size} principles, " \
            "#{static_entries.size} static entries)"
        end

        # Generates the per-file CODEOWNERS rules that route each distilled
        # file's approval to its SSOT-owning team. Emits a gem-managed block
        # (delimited by CODEOWNERS_BEGIN/CODEOWNERS_END) inserted immediately
        # after the broad `/.ai/` rule, so CODEOWNERS last-match-wins overrides
        # the broad AI-harness owners on a per-file basis.
        #
        # Idempotent: replaces an existing managed block, or inserts one after
        # the `/.ai/` rule on first run. Aborts if the `/.ai/` anchor is
        # missing (the placement contract would otherwise silently break).
        def generate_codeowners
          path = Workspace.safe_join(CODEOWNERS_PATH)
          unless File.exist?(path)
            puts Rainbow("  #{CODEOWNERS_PATH} not found; skipping CODEOWNERS generation").faint
            return
          end

          content = File.read(path)
          block = build_codeowners_block
          updated = replace_or_insert_codeowners_block(content, block)

          if updated == content
            puts Rainbow('  CODEOWNERS already up to date').faint
            return
          end

          File.write(path, updated)
          puts "  Updated #{CODEOWNERS_PATH} (#{principles.size} per-file owner rules)"
        end

        # Idempotent. Updates existing notes if wording changed.
        def inject_prerequisite_notes
          principles.each_key do |name|
            note = prerequisite_note(name)
            next unless note

            path = Workspace.safe_join(principles_path(name))
            next unless File.exist?(path)

            content = File.read(path)

            auto_header_pattern = /^(<!-- Auto-generated.*-->)\n\n*/

            if content.include?('> **Prerequisite:**')
              stripped = content.sub(/^> \*\*Prerequisite:\*\*.*\n\n+/, '')
              updated = stripped.sub(auto_header_pattern, "\\1\n\n#{note}")
              next if updated == content

              File.write(path, updated)
              puts "  #{name}: updated prerequisite note"
              next
            end

            updated = content.sub(auto_header_pattern, "\\1\n\n#{note}")
            next if updated == content

            File.write(path, updated)
            puts "  #{name}: injected prerequisite note"
          end
        end

        # Returns the blockquote note to prepend to a non-prerequisite
        # distilled file, or nil if no prerequisite siblings apply.
        def prerequisite_note(name)
          config = principle_config(name)
          return if config.nil? || config['prerequisite']

          group = config['group']
          return if group.nil?

          prereqs = principles.select do |n, c|
            n != name && c['group'] == group && c['prerequisite']
          end
          return if prereqs.empty?

          paths = prereqs.keys.map { |n| ".ai/principles/distilled/#{n}.md" }.join(', ')
          note = "> **Prerequisite:** If you haven't already, also read #{paths} - " \
            "it contains foundational rules that apply to all #{group.downcase} work."
          "#{note}\n\n"
        end

        private

        # Surfaces misconfigured principles at load time. Only invoked
        # from `load`; specs injecting via `data=` skip this.
        def validate_principles!
          missing_sources = []
          missing_owner = []
          principles.each do |name, config|
            missing_sources << name if Array(config['sources']).empty?
            missing_owner << name if config['owner_team'].to_s.strip.empty?
          end

          errors = []
          errors << "missing required `sources:` entries: #{missing_sources.join(', ')}" if missing_sources.any?

          if missing_owner.any?
            errors << "missing required `owner_team:` (the SSOT-owning CODEOWNERS team): #{missing_owner.join(', ')}"
          end

          team_slug_conflicts.each do |handle, slugs|
            errors << "conflicting `team_slug:` values (#{slugs.join(', ')}) for owner_team #{handle} " \
              '(principles sharing an owner_team must agree on the branch slug)'
          end

          return if errors.empty?

          abort Rainbow("ERROR: manifest.yml principles #{errors.join('; ')}").red
        end

        # Detects principles that share an owner_team handle but declare
        # different team_slug values. The fan-out groups by owner_team and
        # derives one branch suffix per handle, so divergent slugs would
        # silently drop all but the first. Returns { handle => [slugs] }.
        def team_slug_conflicts
          principles.values
            .group_by { |config| config['owner_team'] }
            .each_with_object({}) do |(handle, configs), conflicts|
              next if handle.nil?

              slugs = configs.filter_map { |config| config['team_slug'] }.uniq
              conflicts[handle] = slugs if slugs.size > 1
            end
        end

        def principles_filename(name)
          "#{name}.md"
        end

        def slugify(label)
          label.to_s.downcase.strip.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
        end

        # "@gitlab-org/maintainers/database" -> "database". A multi-handle
        # owner_team (e.g. "@abdwdd @alexpooley") has no meaningful segment, so
        # the caller should provide an explicit team_slug in that case; we fall
        # back to the first token's last segment to stay deterministic.
        def last_handle_segment(handle)
          handle.to_s.split(/\s+/).first.to_s.delete_prefix('@').split('/').last
        end

        # Returns the explicit team_slug declared by any principle owned by the
        # given handle, or nil. Lets a handle-keyed lookup (from the fan-out)
        # pick up a per-principle override.
        def explicit_slug_for_handle(handle)
          owner = principles.values.find do |config|
            config['owner_team'] == handle && config['team_slug']
          end
          owner&.dig('team_slug')
        end

        # Builds the gem-managed CODEOWNERS block body (markers included),
        # one rule per principle in manifest declaration order:
        #   /.ai/principles/distilled/<name>.md <owner_team> [<secondary...>]
        def build_codeowners_block
          rules = principles.keys.map do |name|
            owners = [principle_owner_team(name), *principle_secondary_teams(name)]
              .compact.reject(&:empty?).join(' ')
            "/#{PRINCIPLES_DIR}/#{name}.md #{owners}"
          end

          [CODEOWNERS_BEGIN, *rules, CODEOWNERS_END].join("\n")
        end

        # Replaces an existing managed block in place, or inserts a new one on
        # the line after the broad `/.ai/` rule. Aborts when neither a managed
        # block nor the `/.ai/` anchor is present.
        def replace_or_insert_codeowners_block(content, block)
          existing = /^#{Regexp.escape(CODEOWNERS_BEGIN)}\n.*?^#{Regexp.escape(CODEOWNERS_END)}$/mo
          return content.sub(existing, block) if content.match?(existing)

          unless content.match?(CODEOWNERS_AI_RULE)
            abort Rainbow("ERROR: #{CODEOWNERS_PATH} has no `/.ai/` rule to anchor the " \
              'generated CODEOWNERS block after').red
          end

          content.sub(CODEOWNERS_AI_RULE) { |rule| "#{rule}\n#{block}" }
        end

        # Routing-table body shared by AGENTS.md and the SKILL.md files.
        def build_skill_routing_table
          groups = {}
          groups_order = []
          principles.each do |name, config|
            group = config['group'] || 'Other'
            unless groups.key?(group)
              groups[group] = []
              groups_order << group
            end

            groups[group] << { name: name, description: config['description'],
                               prerequisite: config['prerequisite'] == true }
          end

          lines = [
            'Evaluate ALL groups below and load principles from EVERY group that applies to',
            'your task. Most tasks span multiple groups (e.g., a model change may need',
            'Backend, Database, and Testing principles). DO NOT stop after the first group.',
            'When your task involves database queries, scopes, or data access patterns,',
            'ALWAYS load Database principles regardless of which files you are editing.',
            ''
          ]
          groups_order.each do |group|
            lines << "**#{group}:**"
            prerequisites = groups[group].select { |e| e[:prerequisite] }

            groups[group].each do |entry|
              line = "- **#{entry[:description]}**: Read .ai/principles/distilled/#{entry[:name]}.md"
              line += agents_md_prerequisite_suffix(entry, prerequisites, group)
              lines << line
            end

            lines << ''
          end

          static_entries.each do |entry|
            lines << "- **#{entry['description']}**: Read #{entry['path']}"
          end

          lines.join("\n")
        end

        def agents_md_prerequisite_suffix(entry, prerequisites, group)
          if entry[:prerequisite]
            " *(load for any #{group.downcase} work)*"
          elsif prerequisites.any?
            also = prerequisites.map { |p| ".ai/principles/distilled/#{p[:name]}.md" }.join(', ')
            " *(also load: #{also})*"
          else
            ''
          end
        end
      end
    end
  end
end
