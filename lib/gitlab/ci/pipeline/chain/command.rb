module Gitlab # rubocop:disable Naming/FileName
  module Ci
    module Pipeline
      module Chain
        Command = Struct.new(
          :source, :project, :current_user,
          :origin_ref, :checkout_sha, :after_sha, :before_sha,
          :trigger_request, :schedule,
          :ignore_skip_ci, :save_incompleted,
          :seeds_block, :variables_attributes
        ) do
          include Gitlab::Utils::StrongMemoize

          def initialize(**params)
            params.each do |key, value|
              self[key] = value
            end
          end

          def branch_exists?
            strong_memoize(:is_branch) do
              project.repository.branch_exists?(ref)
            end
          end

          def tag_exists?
            strong_memoize(:is_tag) do
              project.repository.tag_exists?(ref)
            end
          end

          def ref
            strong_memoize(:ref) do
              Gitlab::Git.ref_name(origin_ref)
            end
          end

          def sha
            strong_memoize(:sha) do
              project.commit(origin_sha || origin_ref).try(:id)
            end
          end

          def origin_sha
            checkout_sha || after_sha
          end

          def before_sha
            self[:before_sha] || checkout_sha || Gitlab::Git::BLANK_SHA
          end

          def protected_ref?
            strong_memoize(:protected_ref) do
              project.protected_for?(ref)
            end
          end
        end
      end
    end
  end
end
