module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Limit
            class Activity < ::Gitlab::Ci::Pipeline::Chain::Base
              include ::Gitlab::Ci::Pipeline::Chain::Helpers
              include ::Gitlab::OptimisticLocking

              def initialize(*)
                super

                @limit = Pipeline::Quota::Activity
                  .new(project.namespace, pipeline.project)
              end

              def perform!
                return unless @limit.exceeded?

                # TODO, add failure reason
                # TODO, transaction?

                @pipeline.cancel_running

                retry_optimistic_lock(@pipeline)
                  @pipeline.drop!
                end

                # TODO, should we invalidate the pipeline
                # while it is already persisted?
                #
                # Should we show info in the UI or alert/warning?
                #
                error(@limit.message)
              end

              def break?
                @limit.exceeded?
              end
            end
          end
        end
      end
    end
  end
end
