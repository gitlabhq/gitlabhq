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
              if force_pipeline_creation_to_continue?
                @command.pipeline_creation_forced_to_continue = true
              else
                return error(
                  ::Ci::Pipeline.rules_failure_message,
                  failure_reason: :filtered_by_rules
                )
              end
            end

            return error('Failed to build the pipeline!') if pipeline.invalid?

            raise Populate::PopulateError if pipeline.persisted?
          end

          def break?
            pipeline.errors.any?
          end

          private

          def no_pipeline_to_create?
            stage_names.empty?
          end

          def stage_names
            # We filter out `.pre/.post` stages, as they alone are not considered
            # a complete pipeline:
            # https://gitlab.com/gitlab-org/gitlab/issues/198518
            pipeline.stages.map(&:name) - ::Gitlab::Ci::Config::Stages::EDGES
          end

          # Overridden in EE
          def force_pipeline_creation_to_continue?
            false
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Populate.prepend_mod
