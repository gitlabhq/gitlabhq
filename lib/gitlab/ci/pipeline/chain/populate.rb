# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Populate < Chain::Base
          include Chain::Helpers

          PopulateError = Class.new(StandardError)

          def perform!
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
            if seeds_errors = pipeline.stage_seeds.flat_map(&:errors).compact.presence
              return error(seeds_errors.join("\n"), config_error: true)
            end

            ##
            # Populate pipeline with all stages, and stages with builds.
            #
            pipeline.stages = pipeline.stage_seeds.map(&:to_resource)

            if pipeline.stages.none?
              return error('No stages / jobs for this pipeline.')
            end

            if pipeline.invalid?
              return error('Failed to build the pipeline!')
            end

            raise Populate::PopulateError if pipeline.persisted?
          end

          def break?
            pipeline.errors.any?
          end
        end
      end
    end
  end
end
