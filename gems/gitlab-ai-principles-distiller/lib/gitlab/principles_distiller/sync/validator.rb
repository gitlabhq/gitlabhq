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

          success
        end

        private

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
