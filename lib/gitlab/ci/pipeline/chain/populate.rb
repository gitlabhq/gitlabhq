module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Populate < Chain::Base
          include Chain::Helpers

          PopulateError = Class.new(StandardError)

          def perform!
            ##
            # Populate pipeline with seeds block.
            #
            # It comes from a block argument to CreatePipelineService#execute.
            #
            @command.seeds_block&.call(pipeline)

            pipeline.stage_seeds.each do |seed|
              seed.user = current_user

              pipeline.stages << seed.to_resource
            end

            if pipeline.invalid?
              error('Failed to build the pipeline!')
            end

            raise Populate::PopulateError if pipeline.persisted?
          end

          def break?
            pipeline.invalid?
          end
        end
      end
    end
  end
end
