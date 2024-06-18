# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Seed < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            raise ArgumentError, 'missing YAML processor result' unless @command.yaml_processor_result
            raise ArgumentError, 'missing workflow rules result' unless @command.workflow_rules_result

            # Allocate next IID. This operation must be outside of transactions of pipeline creations.
            logger.instrument(:pipeline_allocate_seed_attributes, once: true) do
              pipeline.ensure_project_iid!
              pipeline.ensure_ci_ref!
            end

            # Protect the pipeline. This is assigned in Populate instead of
            # Build to prevent erroring out on ambiguous refs.
            pipeline.protected = @command.protected_ref?

            ##
            # Gather all runtime build/stage errors
            #
            seed_errors = logger.instrument(:pipeline_seed_evaluation, once: true) do
              pipeline_seed.errors
            end

            return error(seed_errors.join("\n"), failure_reason: :config_error) if seed_errors

            @command.pipeline_seed = pipeline_seed
          end

          def break?
            pipeline.errors.any?
          end

          private

          def pipeline_seed
            logger.instrument(:pipeline_seed_initialization, once: true) do
              stages_attributes = @command.yaml_processor_result.stages_attributes

              Gitlab::Ci::Pipeline::Seed::Pipeline.new(context, stages_attributes)
            end
          end
          strong_memoize_attr :pipeline_seed

          def context
            Gitlab::Ci::Pipeline::Seed::Context.new(
              pipeline,
              root_variables: root_variables,
              logger: logger
            )
          end

          def root_variables
            ::Gitlab::Ci::Variables::Helpers.merge_variables(
              @command.yaml_processor_result.root_variables,
              @command.workflow_rules_result.variables)
          end
          strong_memoize_attr :root_variables
        end
      end
    end
  end
end
