# frozen_string_literal: true

module Gitlab
  module Git
    module Patches
      class CommitPatches
        include Gitlab::Git::WrapsGitalyErrors

        def initialize(user, repository, branch, patch_collection, target_sha)
          @user = user
          @repository = repository
          @branch = branch
          @patches = patch_collection
          @target_sha = target_sha
        end

        def commit
          repository.with_cache_hooks do
            wrapped_gitaly_errors do
              operation_service.user_commit_patches(user,
                branch_name: branch,
                patches: patches.content,
                target_sha: target_sha
              )
            end
          end
        end

        private

        attr_reader :user, :repository, :branch, :patches, :target_sha

        def operation_service
          repository.raw.gitaly_operation_client
        end
      end
    end
  end
end
