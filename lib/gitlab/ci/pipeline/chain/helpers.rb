module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          include Gitlab::Utils::StrongMemoize

          def branch_exists?
            strong_memoize(:is_branch) do
              project.repository.branch_exists?(pipeline.ref)
            end
          end

          def tag_exists?
            strong_memoize(:is_tag) do
              project.repository.tag_exists?(pipeline.ref)
            end
          end

          def error(message)
            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
