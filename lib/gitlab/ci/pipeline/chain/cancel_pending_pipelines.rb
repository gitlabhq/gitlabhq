# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CancelPendingPipelines < Chain::Base
          def perform!
            ::Ci::CancelRedundantPipelinesWorker.perform_async(pipeline.id)
          end

          def break?
            false
          end
        end
      end
    end
  end
end
