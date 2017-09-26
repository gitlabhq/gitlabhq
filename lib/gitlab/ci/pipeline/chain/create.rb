module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          def perform!
            ::Ci::Pipeline.transaction do
              pipeline.save!

              if @command.seeds_block
                @command.seeds_block.call(pipeline)
              end

              ::Ci::CreatePipelineStagesService
                .new(project, current_user)
                .execute(pipeline)
            end
          rescue ActiveRecord::RecordInvalid => e
            pipeline.erros.add(:base, "Failed to persist the pipeline: #{e}")
          end

          def break?
            !pipeline.persisted?
          end
        end
      end
    end
  end
end
