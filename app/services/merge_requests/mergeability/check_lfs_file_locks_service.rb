# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckLfsFileLocksService < CheckBaseService
      include ::Gitlab::Utils::StrongMemoize

      identifier :locked_lfs_files
      description <<~DESC.chomp
        Checks whether the merge request contains locked LFS files that are locked by users other than the merge request author
      DESC

      CACHE_KEY = 'merge_request:%{id}:%{sha}:lfs_file_locks_mergeability:%{epoch}'

      def execute
        return inactive if check_inactive?
        return failure if contains_locked_lfs_files?

        success
      end

      def skip?
        params[:skip_locked_lfs_files_check].present?
      end

      def cacheable?
        true
      end

      def cache_key
        # If the feature is disabled we will return inactive so we don't need to
        # link the cache key to a specific MR.
        return 'inactive_lfs_file_locks_mergeability_check' if check_inactive?

        # Cache is linked to a specific MR
        id = merge_request.id
        # Cache is invalidated when new changes are added
        sha = merge_request.diff_head_sha
        # Cache is invalidated when lfs_file_locks are added or removed
        epoch = project.lfs_file_locks_changed_epoch

        format(CACHE_KEY, id: id, sha: sha, epoch: epoch)
      end

      private

      delegate :project, :author_id, :changed_paths, to: :merge_request

      def contains_locked_lfs_files?
        return false unless project.lfs_file_locks.exists?

        paths = changed_paths.map(&:path).uniq
        project.lfs_file_locks.for_paths(paths).not_for_users(author_id).exists?
      end

      def check_inactive?
        !project.lfs_enabled?
      end
      strong_memoize_attr :check_inactive?
    end
  end
end
