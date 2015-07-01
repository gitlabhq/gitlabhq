module MergeRequests
  # AutoMergeService class
  #
  # Do git merge in satellite and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Called when you do merge via GitLab UI
  class AutoMergeService < BaseMergeService
    attr_reader :merge_request, :commit_message

    def execute(merge_request, commit_message)
      @commit_message = commit_message
      @merge_request = merge_request

      merge_request.lock_mr

      if merge!
        merge_request.merge
        create_merge_event(merge_request, current_user)
        create_note(merge_request)
        notification_service.merge_mr(merge_request, current_user)
        execute_hooks(merge_request, 'merge')
        true
      else
        merge_request.unlock_mr
        false
      end
    rescue
      merge_request.unlock_mr if merge_request.locked?
      merge_request.mark_as_unmergeable
      false
    end

    def merge!
      if merge_request.for_fork?
        Gitlab::Satellite::MergeAction.new(current_user, merge_request).merge!(commit_message)
      else
        # Merge local branches using rugged instead of satellites
        if sha = commit
          after_commit(sha, merge_request.target_branch)
        end
      end
    end

    def commit
      committer = repository.user_to_comitter(current_user)

      options = {
        message: commit_message,
        author: committer,
        committer: committer
      }

      repository.merge(merge_request.source_branch, merge_request.target_branch, options)
    end

    def after_commit(sha, branch)
      commit = repository.commit(sha)
      full_ref = 'refs/heads/' + branch
      old_sha = commit.parent_id || Gitlab::Git::BLANK_SHA
      GitPushService.new.execute(project, current_user, old_sha, sha, full_ref)
    end

    def repository
      project.repository
    end
  end
end
