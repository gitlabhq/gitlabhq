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

            return if workflow_passed?

            if force_pipeline_creation_to_continue?
              # Usually we exit early here, leaving the pipeline data structure
              # from CI config untouched.
              # Since we are forcing the process to continue, we need to ensure that
              # we empty the data structure from the CI config, otherwise
              # the seeding phase will populate the pipeline with jobs.
              #
              # Example: With Pipeline Execution Policies we want to inject policy
              # jobs even if the project pipeline is filtered out by workflow:rules.
              @command.yaml_processor_result&.clear_jobs!

              return
            end

            error(
              ::Ci::Pipeline.workflow_rules_failure_message,
              failure_reason: :filtered_by_workflow_rules
            )
          end

          def break?
            @pipeline.errors.any? || @pipeline.persisted?
          end

          private

          def workflow_passed?
            workflow_rules_result.pass?
          end

          def workflow_rules_result
            workflow_rules.evaluate(@pipeline, global_context)
          end
          strong_memoize_attr :workflow_rules_result

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
            @command.yaml_processor_result.workflow_rules
          end
          strong_memoize_attr :workflow_rules_config

          # rubocop:disable Gitlab/NoCodeCoverageComment -- method is tested in EE
          # :nocov:
          # Overridden in EE
          def force_pipeline_creation_to_continue?
            false
          end
          # :nocov:
          # rubocop:enable Gitlab/NoCodeCoverageComment
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.prepend_mod
