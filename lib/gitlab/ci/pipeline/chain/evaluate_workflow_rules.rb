# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EvaluateWorkflowRules < Chain::Base
          include ::Gitlab::Utils::StrongMemoize
          include Chain::Helpers

          def perform!
            error('Pipeline filtered out by workflow rules.') unless workflow_passed?
          end

          def break?
            @pipeline.errors.any? || @pipeline.persisted?
          end

          private

          def workflow_passed?
            strong_memoize(:workflow_passed) do
              workflow_rules.evaluate(@pipeline, global_context).pass?
            end
          end

          def workflow_rules
            Gitlab::Ci::Build::Rules.new(
              workflow_config[:rules], default_when: 'always')
          end

          def global_context
            Gitlab::Ci::Build::Context::Global.new(
              @pipeline, yaml_variables: workflow_config[:yaml_variables])
          end

          def has_workflow_rules?
            workflow_config[:rules].present?
          end

          def workflow_config
            @command.yaml_processor_result.workflow_attributes || {}
          end
        end
      end
    end
  end
end
