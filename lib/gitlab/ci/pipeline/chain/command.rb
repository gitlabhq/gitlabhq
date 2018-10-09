module Gitlab # rubocop:disable Naming/FileName
  module Ci
    module Pipeline
      module Chain
        Command = Struct.new(
          :pipeline,
          :project, :current_user,
          :ignore_skip_ci, :save_incompleted,
          :seeds_block
        ) do
          include Gitlab::Utils::StrongMemoize

          def initialize(**params)
            params.each do |key, value|
              self[key] = value
            end
          end

          def branch_exists?
            strong_memoize(:is_branch) do
              project.repository.branch_exists?(ref) && !pipeline.tag?
            end
          end
      
          def tag_exists?
            strong_memoize(:is_tag) do
              project.repository.tag_exists?(ref) && pipeline.tag?
            end
          end

          def protected_ref?
            pipeline.protected?
          end

          def ref
            pipeline.ref
          end

          def sha
            pipeline.sha
          end
        end
      end
    end
  end
end
