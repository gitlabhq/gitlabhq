# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EvaluateWorkflowRules < Chain::Base
          include ::Gitlab::Utils::StrongMemoize
          include Chain::Helpers

          def perform!
            @command.workflow_rules_result = workflow_rules_result

            error('Pipeline filtered out by workflow rules.') unless workflow_passed?
          end

          def break?
            @pipeline.errors.any? || @pipeline.persisted?
          end

          private

          def workflow_passed?
            workflow_rules_result.pass?
          end

          def workflow_rules_result
            strong_memoize(:workflow_rules_result) do
              workflow_rules.evaluate(@pipeline, global_context)
            end
          end

          def workflow_rules
            Gitlab::Ci::Build::Rules.new(
              workflow_rules_config, default_when: 'always')
          end

          def global_context
            Gitlab::Ci::Build::Context::Global.new(
              @pipeline, yaml_variables: @command.yaml_processor_result.root_variables)
          end

          def has_workflow_rules?
            workflow_rules_config.present?
          end

          def workflow_rules_config
            strong_memoize(:workflow_rules_config) do
              @command.yaml_processor_result.workflow_rules
            end
          end
        end
      end
    end
  end
end
