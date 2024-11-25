# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Populate < Chain::Base
          include Chain::Helpers

          PopulateError = Class.new(StandardError)

          def perform!
            raise ArgumentError, 'missing pipeline seed' unless @command.pipeline_seed

            ##
            # Populate pipeline with all stages, and stages with builds.
            #
            pipeline.stages = @command.pipeline_seed.stages

            if no_pipeline_to_create?
              return error(
                ::Ci::Pipeline.rules_failure_message,
                failure_reason: :filtered_by_rules
              )
            end

            return error('Failed to build the pipeline!') if pipeline.invalid?

            raise Populate::PopulateError if pipeline.persisted?
          end

          def break?
            pipeline.errors.any?
          end

          private

          def no_pipeline_to_create?
            # If there are security policy pipelines,
            # they will be merged onto the pipeline in PipelineExecutionPolicies::ApplyPolicies
            stage_names.empty? && !@command.pipeline_policy_context&.has_execution_policy_pipelines?
          end

          def stage_names
            # We filter out `.pre/.post` stages, as they alone are not considered
            # a complete pipeline:
            # https://gitlab.com/gitlab-org/gitlab/issues/198518
            pipeline.stages.map(&:name) - ::Gitlab::Ci::Config::EdgeStagesInjector::EDGES
          end
        end
      end
    end
  end
end
