# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class TriggerBuildHooks < Chain::Base
          def perform!
            return unless project.has_active_hooks?(:job_hooks) || project.has_active_integrations?(:job_hooks)

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
