# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Seed < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            raise ArgumentError, 'missing config processor' unless @command.config_processor

            # Allocate next IID. This operation must be outside of transactions of pipeline creations.
            pipeline.ensure_project_iid!

            # Protect the pipeline. This is assigned in Populate instead of
            # Build to prevent erroring out on ambiguous refs.
            pipeline.protected = @command.protected_ref?

            ##
            # Populate pipeline with block argument of CreatePipelineService#execute.
            #
            @command.seeds_block&.call(pipeline)

            ##
            # Gather all runtime build/stage errors
            #
            if stage_seeds_errors
              return error(stage_seeds_errors.join("\n"), config_error: true)
            end

            @command.stage_seeds = stage_seeds
          end

          def break?
            pipeline.errors.any?
          end

          private

          def stage_seeds_errors
            stage_seeds.flat_map(&:errors).compact.presence
          end

          def stage_seeds
            strong_memoize(:stage_seeds) do
              seeds = stages_attributes.inject([]) do |previous_stages, attributes|
                seed = Gitlab::Ci::Pipeline::Seed::Stage.new(pipeline, attributes, previous_stages)
                previous_stages + [seed]
              end

              seeds.select(&:included?)
            end
          end

          def stages_attributes
            @command.config_processor.stages_attributes
          end
        end
      end
    end
  end
end
