# frozen_string_literal: true

module Gitlab
  module Git
    module Patches
      class CommitPatches
        include Gitlab::Git::WrapsGitalyErrors

        def initialize(user, repository, branch, patch_collection)
          @user = user
          @repository = repository
          @branch = branch
          @patches = patch_collection
        end

        def commit
          repository.with_cache_hooks do
            wrapped_gitaly_errors do
              operation_service.user_commit_patches(user, branch, patches.content)
            end
          end
        end

        private

        attr_reader :user, :repository, :branch, :patches

        def operation_service
          repository.raw.gitaly_operation_client
        end
      end
    end
  end
end
