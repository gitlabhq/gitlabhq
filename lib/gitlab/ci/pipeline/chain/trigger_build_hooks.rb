# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class TriggerBuildHooks < Chain::Base
          def perform!
            ::Ci::ExecutePipelineBuildHooksWorker.perform_async(pipeline.id)
          end

          def break?
            false
          end
        end
      end
    end
  end
end
