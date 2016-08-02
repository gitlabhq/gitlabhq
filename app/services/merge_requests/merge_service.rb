module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class MergeService < MergeRequests::BaseService
    attr_reader :merge_request

    def execute(merge_request)
      @merge_request = merge_request

      return error('Merge request is not mergeable') unless @merge_request.mergeable?

      merge_request.in_locked_state do
        if commit
          after_merge
          success
        else
          error('Can not merge changes')
        end
      end
    end

    private

    def commit
      committer = repository.user_to_committer(current_user)

      options = {
        message: merge_request.commit_message || merge_request.merge_commit_message,
        author: committer,
        committer: committer
      }

      commit_id = repository.merge(current_user, merge_request, options)

      if commit_id
        merge_request.update(merge_commit_sha: commit_id)
      else
        merge_request.update(merge_error: 'Conflicts detected during merge')
        false
      end
    rescue GitHooksService::PreReceiveError => e
      merge_request.update(merge_error: e.message)
      false
    rescue StandardError => e
      merge_request.update(merge_error: "Something went wrong during merge")
      Rails.logger.error(e.message)
      false
    ensure
      merge_request.update(in_progress_merge_commit_sha: nil)
    end

    def after_merge
      MergeRequests::PostMergeService.new(project, current_user).execute(merge_request)

      if merge_request.remove_source_branch? && merge_request.can_remove_source_branch?(branch_deletion_user)
        DeleteBranchService.new(@merge_request.source_project, branch_deletion_user).
          execute(merge_request.source_branch)
      end
    end

    def branch_deletion_user
      @merge_request.remove_source_branch? ? @merge_request.author : current_user
    end
  end
end
