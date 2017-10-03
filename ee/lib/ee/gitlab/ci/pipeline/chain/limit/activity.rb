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

                retry_optimistic_lock(@pipeline) do
                  @pipeline.drop!(:activity_limit_exceeded)
                end
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
