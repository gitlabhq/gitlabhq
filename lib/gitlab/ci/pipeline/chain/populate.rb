module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Populate < Chain::Base
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

            raise Populate::PopulateError if pipeline.persisted?
          end

          def break?
            pipeline.persisted?
          end
        end
      end
    end
  end
end
