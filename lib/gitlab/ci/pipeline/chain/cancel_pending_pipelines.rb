# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CancelPendingPipelines < Chain::Base
          def perform!
            if pipeline.schedule?
              ::Ci::LowUrgencyCancelRedundantPipelinesWorker.perform_async(pipeline.id)
            else
              ::Ci::CancelRedundantPipelinesWorker.perform_async(pipeline.id)
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
