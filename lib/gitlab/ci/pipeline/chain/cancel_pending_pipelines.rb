# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CancelPendingPipelines < Chain::Base
          def perform!
            cancellation_worker_class.perform_async(pipeline.id, { 'partition_id' => pipeline.partition_id })
          end

          def break?
            false
          end

          private

          def cancellation_worker_class
            if pipeline.schedule?
              ::Ci::LowUrgencyCancelRedundantPipelinesWorker
            else
              ::Ci::CancelRedundantPipelinesWorker
            end
          end
        end
      end
    end
  end
end
