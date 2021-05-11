# frozen_string_literal: true

module Git
  class BranchPushService < ::BaseService
    include Gitlab::Access
    include Gitlab::Utils::StrongMemoize
    include ChangeParams

    # This method will be called after each git update
    # and only if the provided user and project are present in GitLab.
    #
    # All callbacks for post receive action should be placed here.
    #
    # Next, this method:
    #  1. Creates the push event
    #  2. Updates merge requests
    #  3. Recognizes cross-references from commit messages
    #  4. Executes the project's webhooks
    #  5. Executes the project's services
    #  6. Checks if the project's main language has changed
    #
    def execute
      return unless Gitlab::Git.branch_ref?(ref)

      enqueue_update_mrs
      enqueue_detect_repository_languages

      execute_related_hooks
      perform_housekeeping

      stop_environments
      unlock_artifacts

      true
    end

    # Update merge requests that may be affected by this push. A new branch
    # could cause the last commit of a merge request to change.
    def enqueue_update_mrs
      return if params[:merge_request_branches]&.exclude?(branch_name)

      UpdateMergeRequestsWorker.perform_async(
        project.id,
        current_user.id,
        oldrev,
        newrev,
        ref
      )
    end

    def enqueue_detect_repository_languages
      return unless default_branch?

      DetectRepositoryLanguagesWorker.perform_async(project.id)
    end

    # Only stop environments if the ref is a branch that is being deleted
    def stop_environments
      return unless removing_branch?

      Ci::StopEnvironmentsService.new(project, current_user).execute(branch_name)
    end

    def unlock_artifacts
      return unless removing_branch?

      Ci::RefDeleteUnlockArtifactsWorker.perform_async(project.id, current_user.id, ref)
    end

    def execute_related_hooks
      BranchHooksService.new(project, current_user, params).execute
    end

    def perform_housekeeping
      housekeeping = Repositories::HousekeepingService.new(project)
      housekeeping.increment!
      housekeeping.execute if housekeeping.needed?
    rescue Repositories::HousekeepingService::LeaseTaken
    end

    def removing_branch?
      Gitlab::Git.blank_ref?(newrev)
    end

    def branch_name
      strong_memoize(:branch_name) { Gitlab::Git.ref_name(ref) }
    end

    def default_branch?
      strong_memoize(:default_branch) do
        [nil, branch_name].include?(project.default_branch)
      end
    end
  end
end

Git::BranchPushService.prepend_mod_with('Git::BranchPushService')
