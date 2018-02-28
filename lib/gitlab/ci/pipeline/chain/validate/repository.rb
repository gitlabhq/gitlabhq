module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Repository < Chain::Base
            include Chain::Helpers

            def perform!
              unless branch_exists? || tag_exists?
                return error('Reference not found')
              end

              ## TODO, we check commit in the service, that is why
              # there is no repository access here.
              #
              unless pipeline.sha
                return error('Commit not found')
              end
            end

            def break?
              @pipeline.errors.any?
            end
          end
        end
      end
    end
  end
end
