module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          class Size < ::Gitlab::Ci::Pipeline::Chain::Base
            include ::Gitlab::Ci::Pipeline::Chain::Helpers

            def initialize(*)
              super

              @limit = Pipeline::Quota::Size
                .new(project.namespace, pipeline)
            end

            def perform!
              return unless @limit.exceeded?
              return unless @command.save_incompleted

              # TODO, add failure reason
              # TODO, add validation error
              @pipeline.drop
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
