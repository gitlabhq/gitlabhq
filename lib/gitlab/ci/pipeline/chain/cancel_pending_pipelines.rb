# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CancelPendingPipelines < Chain::Base
          include Chain::Helpers

          BATCH_SIZE = 25

          def perform!
            if Feature.enabled?(:move_cancel_pending_pipelines_to_async, project)
              ::Ci::CancelRedundantPipelinesWorker.perform_async(pipeline.id)
            else
              ::Ci::PipelineCreation::CancelRedundantPipelinesService.new(pipeline).execute
            end
          end

          def break?
            false
          end
        end
      end
    end
  end
end
