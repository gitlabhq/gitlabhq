module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def branch_exists?
            return @is_branch if defined?(@is_branch)

            @is_branch = project.repository.branch_exists?(pipeline.ref)
          end

          def tag_exists?
            return @is_tag if defined?(@is_tag)

            @is_tag = project.repository.tag_exists?(pipeline.ref)
          end

          def error(message)
            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
