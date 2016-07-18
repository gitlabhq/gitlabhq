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
      if project.merge_requests_ff_only_enabled && !self.is_a?(FfMergeService)
        FfMergeService.new(project, current_user, params).execute(merge_request)
        return
      end

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

    def hooks_validation_pass?(merge_request)
      return true if project.merge_requests_ff_only_enabled

      push_rule = merge_request.project.push_rule
      return true unless push_rule

      unless push_rule.commit_message_allowed?(params[:commit_message])
        merge_request.update(merge_error: "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
        return false
      end

      unless push_rule.author_email_allowed?(current_user.email)
        merge_request.update(merge_error: "Commit author's email '#{current_user.email}' does not follow the pattern '#{push_rule.author_email_regex}'")
        return false
      end

      true
    end

    private

    def commit
      committer = repository.user_to_committer(current_user)

      options = {
        message: params[:commit_message] || merge_request.merge_commit_message,
        author: committer,
        committer: committer
      }

      commit_id = repository.merge(current_user, merge_request, options)
      merge_request.update(merge_commit_sha: commit_id)
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

      if params[:should_remove_source_branch].present? || @merge_request.force_remove_source_branch?
        DeleteBranchService.new(@merge_request.source_project, branch_deletion_user).
          execute(merge_request.source_branch)
      end
    end

    def branch_deletion_user
      @merge_request.force_remove_source_branch? ? @merge_request.author : current_user
    end
  end
end
