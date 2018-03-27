module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Populate < Chain::Base
          include Chain::Helpers

          PopulateError = Class.new(StandardError)

          def perform!
            ##
            # Populate pipeline with block argument of CreatePipelineService#execute.
            #
            @command.seeds_block&.call(pipeline)

            ##
            # Populate pipeline with all stages and builds from pipeline seeds.
            #
            pipeline.stage_seeds.each do |stage|
              pipeline.stages << stage.to_resource

              stage.seeds.each do |build|
                pipeline.builds << build.to_resource
              end
            end

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
