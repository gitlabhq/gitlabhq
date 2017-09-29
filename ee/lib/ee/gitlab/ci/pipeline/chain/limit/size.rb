module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Limit
            class Size < ::Gitlab::Ci::Pipeline::Chain::Base
              include ::Gitlab::Ci::Pipeline::Chain::Helpers

              def initialize(*)
                super

                @limit = Pipeline::Quota::Size
                  .new(project.namespace, pipeline)
              end

              def perform!
                return unless @limit.exceeded?

                if @command.save_incompleted
                  @pipeline.failure_reason = :size_limit_exceeded
                  @pipeline.drop
                end

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
