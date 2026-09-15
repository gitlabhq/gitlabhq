# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Fast, network-free checks that run at commit/MR time (lefthook + a dedicated CI job) so problems fail
      # fast, instead of surfacing mid-run on the weekly scheduled sync after expensive Duo workflows have already
      # started:
      #
      # 1. Every SSOT path referenced by the manifest (each principle's `sources[].path` and `baseline:`) resolves
      #    to a file on the current branch (gitlab-org/gitlab#604077).
      # 2. The distillation prompt still fits the AI Catalog's stored-definition limit, so a prompt edit cannot
      #    make the flow unpublishable (https://gitlab.com/gitlab-org/gitlab/-/issues/608440).
      # 3. Baseline rule placement matches the distilled file.
      class Validator
        def self.run
          new.run
        end

        def manifest
          @manifest ||= Manifest.new
        end

        # Exits non-zero (via abort) when any referenced SSOT path is missing, listing every broken reference so
        # they can be fixed in one pass, or when the distillation prompt exceeds the catalog's size budget.
        def run
          parse_options

          manifest.load

          missing = manifest.missing_source_files
          abort(failure_message(missing)) if missing.any?

          oversized = prompt_size_failure_message
          abort(oversized) if oversized

          misplaced = misplaced_baseline_rules
          abort(misplaced_failure_message(misplaced)) if misplaced.any?

          success
        end

        private

        def misplaced_baseline_rules
          manifest.principles.flat_map do |name, config|
            baseline = config['baseline']
            next [] unless baseline

            baseline_content = manifest.read_repo_file(baseline)
            raw_distilled = manifest.read_repo_file(manifest.principles_path(name))
            next [] unless baseline_content && raw_distilled

            compare_rule_placement(name, baseline_content, manifest.strip_frontmatter(raw_distilled))
          end
        end

        # Reports rules that are duplicated or sit under a heading other than the baseline's; both trip the
        # exactly-once drift guard at run time.
        def compare_rule_placement(name, baseline_content, distilled)
          baseline_sections = BaselineRules.units_by_section(BaselineRules.baseline_rules(baseline_content))
          distilled_sections = BaselineRules.units_by_section(BaselineRules.checklist_body(distilled))

          baseline_sections.filter_map do |unit, baseline_occurrences|
            found = distilled_sections[unit]
            next unless found
            next if found == baseline_occurrences.first(1)

            {
              principle: name,
              rule: unit,
              baseline_section: baseline_occurrences.first,
              distilled_section: found.uniq.map { |section| section || '(no heading)' }.join(', ')
            }
          end
        end

        def misplaced_failure_message(misplaced)
          listed = misplaced.map do |entry|
            <<~ENTRY.chomp
              #{entry[:principle]}
                    rule:      #{truncate_rule(entry[:rule])}
                    baseline:  #{entry[:baseline_section] || '(no heading)'}
                    distilled: #{entry[:distilled_section] || '(no heading)'}
            ENTRY
          end.join("\n\n  - ")

          Rainbow(<<~MESSAGE).red
            ERROR: #{misplaced.size} baseline rule(s) are not placed as the baseline specifies:

              - #{listed}

            The baseline is authoritative for placement, so the agent emits a copy at the baseline's
            heading while leaving the existing one in place, tripping the exactly-once baseline drift
            check. Every retry re-runs identical input, so the principle fails permanently and takes
            the rest of the run's output with it.

            Fix so each rule appears EXACTLY ONCE, under the baseline's heading: MOVE a misplaced
            rule, and delete the surplus copies of a duplicated one. Do not delete every copy — that
            flips the failure from "duplicated" to "omitted".

            See https://gitlab.com/gitlab-org/gitlab/-/issues/616111 for the analysis.
          MESSAGE
        end

        def truncate_rule(rule)
          rule.length > 100 ? "#{rule[0, 97]}..." : rule
        end

        # Guards the prompt against the AI Catalog's stored-definition limit.
        # Returns nil when within budget, or the failure message.
        # The prompt is not a distiller SSOT source, so it perturbs no checksum and nothing else in this validator
        # would notice it growing.
        def prompt_size_failure_message
          prompt_path = Workspace.safe_join(FlowDefinition::PROMPT_PATH)
          # A workspace without the prompt has no flow to publish, so there is no budget to enforce.
          return unless File.exist?(prompt_path)

          yaml_definition = FlowDefinition.build_flow_yaml(FlowDefinition.load_distillation_prompt)
          return if FlowDefinition.within_size_limit?(yaml_definition)

          stored = FlowDefinition.stored_definition_bytesize(yaml_definition)
          over_by = stored - FlowDefinition::DEFINITION_SIZE_LIMIT

          Rainbow(<<~MESSAGE).red
            ERROR: #{FlowDefinition::PROMPT_PATH} is #{over_by} bytes over the AI Catalog limit.

              #{FlowDefinition.size_report(yaml_definition)}

            The AI Catalog stores the parsed YAML *and* the raw YAML string under
            `yaml_definition`, so the prompt is counted twice and one byte of prompt
            costs roughly 2.2 stored bytes. That duplicate storage is tracked in
            https://gitlab.com/gitlab-org/gitlab/-/issues/591638
            — once it moves to object storage this budget roughly doubles.
            Until then, publishing the flow fails with
            "Latest version definition is too large".

            Shorten the prompt by about #{(over_by / 2.2).ceil} bytes. Prefer removing
            duplicated instructions and trimming worked examples over dropping
            normative rules, and DO NOT renumber rules — the prompt cross-references
            its own rule numbers.

            See https://gitlab.com/gitlab-org/gitlab/-/issues/608440 for the byte census and rationale.
          MESSAGE
        end

        def parse_options
          OptionParser.new do |opts|
            opts.banner = 'Usage: gitlab-ai-principles-distiller-validate [options]'

            opts.on('--workspace PATH', 'Path to the repository workspace ' \
              '(defaults to $CI_PROJECT_DIR)') do |path|
              Workspace.path = path
            end
          end.parse!
        end

        def success
          puts Rainbow("All #{manifest.principles.size} principle(s) reference existing SSOT source files.").green
        end

        def failure_message(missing)
          listed = missing.map { |path| "  - #{path}" }.join("\n")

          Rainbow(<<~MESSAGE).red
            ERROR: #{missing.size} SSOT source file(s) referenced by #{Manifest::MANIFEST_PATH} do not exist:
            #{listed}

            A referenced doc was likely moved or renamed. Update the matching `path:`/`baseline:`
            entries in #{Manifest::MANIFEST_PATH} to point at the current file (a doc converted to a
            directory resolves via its `_index.md`).
          MESSAGE
        end
      end
    end
  end
end
