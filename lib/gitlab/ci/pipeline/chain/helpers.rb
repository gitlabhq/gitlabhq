module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          # rubocop:disable Cop/ModuleWithInstanceVariables
          def branch_exists?
            return @is_branch if defined?(@is_branch)

            @is_branch = project.repository.branch_exists?(pipeline.ref)
          end
          # rubocop:enable Cop/ModuleWithInstanceVariables

          # rubocop:disable Cop/ModuleWithInstanceVariables
          def tag_exists?
            return @is_tag if defined?(@is_tag)

            @is_tag = project.repository.tag_exists?(pipeline.ref)
          end
          # rubocop:enable Cop/ModuleWithInstanceVariables

          def error(message)
            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
