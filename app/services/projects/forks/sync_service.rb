# frozen_string_literal: true

module Projects
  module Forks
    # A service for fetching upstream default branch and merging it to the fork's specified branch.
    class SyncService < BaseService
      ONGOING_MERGE_ERROR = 'The synchronization did not happen due to another merge in progress'

      MergeError = Class.new(StandardError)

      def initialize(project, user, target_branch)
        super(project, user)

        @source_project = project.fork_source
        @head_sha = project.repository.commit(target_branch).sha
        @target_branch = target_branch
        @details = Projects::Forks::Details.new(project, target_branch)
      end

      def execute
        execute_service

        ServiceResponse.success
      rescue MergeError => e
        Gitlab::ErrorTracking.log_exception(e, { project_id: project.id, user_id: current_user.id })

        ServiceResponse.error(message: e.message)
      ensure
        details.exclusive_lease.cancel
      end

      private

      attr_reader :source_project, :head_sha, :target_branch, :details

      # The method executes multiple steps:
      #
      # 1. Gitlab::Git::CrossRepo fetches upstream default branch into a temporary ref and returns new source sha.
      # 2. New divergence counts are calculated using the source sha.
      # 3. If the fork is not behind, there is nothing to merge -> exit.
      # 4. Otherwise, continue with the new source sha.
      # 5. If Gitlab::Git::CommandError is raised it means that merge couldn't happen due to a merge conflict. The
      #    details are updated to transfer this error to the user.
      def execute_service
        counts = []
        source_sha = source_project.commit.sha

        Gitlab::Git::CrossRepo.new(repository, source_project.repository)
          .execute(source_sha) do |cross_repo_source_sha|
            counts = repository.diverging_commit_count(head_sha, cross_repo_source_sha)
            ahead, behind = counts
            next if behind == 0

            execute_with_fetched_source(cross_repo_source_sha, ahead)
          end
      rescue Gitlab::Git::CommandError => e
        details.update!({ sha: head_sha, source_sha: source_sha, counts: counts, has_conflicts: true })

        raise MergeError, e.message
      end

      def execute_with_fetched_source(cross_repo_source_sha, ahead)
        with_linked_lfs_pointers(cross_repo_source_sha) do
          merge_commit_id = perform_merge(cross_repo_source_sha, ahead)
          raise MergeError, ONGOING_MERGE_ERROR unless merge_commit_id
        end
      end

      # This method merges the upstream default branch to the fork specified branch.
      # Depending on whether the fork branch is ahead of upstream or not, a different type of
      # merge is performed.
      #
      # If the fork's branch is not ahead of the upstream (only behind), fast-forward merge is performed.
      # However, if the fork's branch contains commits that don't exist upstream, a merge commit is created.
      # In this case, a conflict may happen, which interrupts the merge and returns a message to the user.
      def perform_merge(cross_repo_source_sha, ahead)
        if ahead > 0
          message = "Merge branch #{source_project.path}:#{source_project.default_branch} into #{target_branch}"

          repository.merge_to_branch(current_user,
            source_sha: cross_repo_source_sha,
            target_branch: target_branch,
            target_sha: head_sha,
            message: message)
        else
          repository.ff_merge(current_user, cross_repo_source_sha, target_branch, target_sha: head_sha)
        end
      end

      # This method links the newly merged lfs objects (if any) with the existing ones upstream.
      # The LfsLinkService service has a limit and may raise an error if there are too many lfs objects to link.
      # This is the reason why the block is passed:
      #
      # 1. Verify that there are not too many lfs objects to link
      # 2. Execute the block (which basically performs the merge)
      # 3. Link lfs objects
      def with_linked_lfs_pointers(newrev, &block)
        return yield unless project.lfs_enabled?

        oldrev = head_sha
        new_lfs_oids =
          Gitlab::Git::LfsChanges
            .new(repository, newrev)
            .new_pointers(not_in: [oldrev])
            .map(&:lfs_oid)

        Projects::LfsPointers::LfsLinkService.new(project).execute(new_lfs_oids, &block)
      rescue Projects::LfsPointers::LfsLinkService::TooManyOidsError => e
        raise MergeError, e.message
      end
    end
  end
end
