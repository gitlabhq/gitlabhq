# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class TriggerBuildHooks < Chain::Base
          def perform!
            return unless Feature.enabled?(:ci_trigger_build_hooks_in_chain, pipeline.project)

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
