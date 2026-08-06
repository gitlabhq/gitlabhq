# frozen_string_literal: true

require 'json'
require 'yaml'

require 'rainbow'

require_relative 'workspace'

module Gitlab
  module PrinciplesDistiller
    # Builds the AI Catalog Flow YAML that mirrors `.ai/principles/distillation_prompt.md`, and measures the size
    # the catalog will actually store.
    # Shared by ProvisionFlow (which publishes the definition) and Sync::Validator (which guards it at commit/MR
    # time) so the two can never disagree about what the size is.
    module FlowDefinition
      PROMPT_PATH = '.ai/principles/distillation_prompt.md'

      # Read-only allowlist; names match ee/lib/ai/catalog/built_in_tool_definitions.rb.
      # We curate here rather than rely on agent-side guardrails.
      TOOL_NAMES = %w[
        find_files
        grep
        list_dir
        read_file
        read_files
      ].freeze

      # `Ai::Catalog::ItemVersion` validates the stored `definition` JSONB against 64 KiB
      # (ee/app/models/ai/catalog/item_version.rb), via JsonSchemaValidator's `size_limit`.
      # The effective prompt budget is roughly HALF this number, because the catalog stores the prompt twice
      # (see #stored_definition_bytesize).
      # https://gitlab.com/gitlab-org/gitlab/-/issues/591638 tracks lifting that
      # duplication; until it ships, 64 KiB of storage buys only ~30 KiB of prompt.
      DEFINITION_SIZE_LIMIT = 64 * 1024

      module_function

      # Bytes the catalog will store in the `definition` JSONB column, replicating its JSON encoding.
      # The catalog does NOT store the YAML we submit as-is.
      # It stores the parsed structure merged with the raw YAML string under `yaml_definition`
      # (ee/app/services/ai/catalog/concerns/yaml_definition_parser.rb):
      #
      #   YAML.safe_load(params[:definition]).merge(yaml_definition: params[:definition])
      #
      # So the system prompt is counted TWICE, and only the `yaml_definition` copy carries the block-scalar indentation.
      # Together with JSON escaping, one byte of prompt markdown costs roughly 2.2 stored bytes.
      # Any budget check must therefore measure the stored JSONB, not the YAML we submit.
      # Measuring the YAML is what let https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248765
      # push the definition over the limit unnoticed.
      # This duplication is deliberate on the catalog side (it preserves the original YAML for audit and display
      # fidelity), and https://gitlab.com/gitlab-org/gitlab/-/issues/591638 tracks moving
      # `yaml_definition` to object storage so the stored size no longer doubles.
      # When that lands, this method should be revisited:
      # the `yaml_definition` term drops out and the budget roughly doubles.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/608440
      def stored_definition_bytesize(yaml_definition)
        parsed = YAML.safe_load(yaml_definition)
        rails_json_bytesize(parsed.merge('yaml_definition' => yaml_definition))
      end

      def within_size_limit?(yaml_definition)
        stored_definition_bytesize(yaml_definition) <= DEFINITION_SIZE_LIMIT
      end

      # Reads the prompt SSOT and strips the leading authoring-instructions HTML comment, which is guidance for
      # humans editing the file and not part of the agent's system prompt.
      # The path is always rooted at the workspace via `Workspace.safe_join`, which rejects `..` traversal, and
      # PROMPT_PATH is a frozen constant, so no caller can redirect this read.
      def load_distillation_prompt
        path = Workspace.safe_join(PROMPT_PATH)
        abort Rainbow("ERROR: prompt not found at #{path}").red unless File.exist?(path)

        File.read(path).sub(/\A<!--.*?-->\s*/m, '').strip
      end

      # Single AgentComponent running our distillation prompt; goal is passed at workflow-create time.
      def build_flow_yaml(system_prompt)
        indented_system = indent_block(system_prompt, 8)
        indented_tools  = TOOL_NAMES.map { |t| "    - #{t}" }.join("\n")

        <<~YAML
      version: v1
      environment: ambient
      components:
        - name: distiller
          type: AgentComponent
          prompt_id: distiller_prompt
          inputs:
            - from: context:goal
              as: goal
          toolset:
      #{indented_tools}
          ui_log_events:
            - on_tool_execution_success
            - on_agent_final_answer
            - on_tool_execution_failed
      prompts:
        - prompt_id: distiller_prompt
          name: distiller
          unit_primitives: []
          prompt_template:
            system: |
      #{indented_system}
            user: "{{goal}}"
            placeholder: history
          params:
            timeout: 60
      routers:
        - from: distiller
          to: end
      flow:
        entry_point: distiller
        YAML
      end

      def indent_block(text, spaces)
        pad = ' ' * spaces
        text.each_line.map { |line| line.empty? ? line : "#{pad}#{line}" }.join.chomp
      end

      # Human-readable budget report used by both the provisioner's preflight and the validator's failure message.
      def size_report(yaml_definition)
        stored = stored_definition_bytesize(yaml_definition)

        format(
          'stored definition %<stored>d bytes / %<limit>d limit (%<delta>+d, YAML %<yaml>d bytes)',
          stored: stored,
          limit: DEFINITION_SIZE_LIMIT,
          delta: DEFINITION_SIZE_LIMIT - stored,
          yaml: yaml_definition.bytesize
        )
      end

      # Replicates `Gitlab::Json.dump`'s byte count for a Hash.
      # GitLab runs Oj in `mode: :rails`, which escapes `<`, `>`, `&` (ActiveSupport's
      # `escape_html_entities_in_json`) plus the U+2028/U+2029 line separators.
      # Reproduced with stdlib only, because the `ai-principles-manifest` CI job runs on a bare Ruby image with
      # just `rainbow` installed and has no Oj.
      # Verified byte-identical to `Oj.dump(hash, mode: :rails)` for the current prompt;
      # escaping MORE than Oj would only over-report, never let an oversized definition through.
      def rails_json_bytesize(hash)
        JSON.generate(hash)
          .gsub('<', '\u003c')
          .gsub('>', '\u003e')
          .gsub('&', '\u0026')
          .gsub("\u2028", '\u2028')
          .gsub("\u2029", '\u2029')
          .bytesize
      end
    end
  end
end
