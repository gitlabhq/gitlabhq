module MergeRequests
  class RefreshService < MergeRequests::BaseService
    def execute(oldrev, newrev, ref)
      return true unless Gitlab::Git.branch_ref?(ref)

      @oldrev, @newrev = oldrev, newrev
      @branch_name = Gitlab::Git.ref_name(ref)

      find_new_commits
      # Be sure to close outstanding MRs before reloading them to avoid generating an
      # empty diff during a manual merge
      close_merge_requests
      reload_merge_requests
      reset_merge_when_build_succeeds
      mark_pending_todos_done

      # Leave a system note if a branch was deleted/added
      if branch_added? || branch_removed?
        comment_mr_branch_presence_changed
      end

      comment_mr_with_commits
      execute_mr_web_hooks
      reset_approvals_for_merge_requests

      true
    end

    private

    # Collect open merge requests that target same branch we push into
    # and close if push to master include last commit from merge request
    # We need this to close(as merged) merge requests that were merged into
    # target branch manually
    def close_merge_requests
      commit_ids = @commits.map(&:id)
      merge_requests = @project.merge_requests.opened.where(target_branch: @branch_name).to_a
      merge_requests = merge_requests.select(&:diff_head_commit)

      merge_requests = merge_requests.select do |merge_request|
        commit_ids.include?(merge_request.diff_head_sha)
      end

      merge_requests.uniq.select(&:source_project).each do |merge_request|
        MergeRequests::PostMergeService.
          new(merge_request.target_project, @current_user).
          execute(merge_request)
      end
    end

    def force_push?
      Gitlab::Checks::ForcePush.force_push?(@project, @oldrev, @newrev)
    end

    # Refresh merge request diff if we push to source or target branch of merge request
    # Note: we should update merge requests from forks too
    def reload_merge_requests
      merge_requests = @project.merge_requests.opened.by_branch(@branch_name).to_a
      merge_requests += fork_merge_requests.by_branch(@branch_name).to_a
      merge_requests = filter_merge_requests(merge_requests)

      merge_requests.each do |merge_request|
        if merge_request.source_branch == @branch_name || force_push?
          merge_request.reload_diff
        else
          mr_commit_ids = merge_request.commits.map(&:id)
          push_commit_ids = @commits.map(&:id)
          matches = mr_commit_ids & push_commit_ids
          merge_request.reload_diff if matches.any?
        end

        merge_request.mark_as_unchecked
      end
    end

    # Reset approvals for merge request
    def reset_approvals_for_merge_requests
      merge_requests_for_source_branch.each do |merge_request|
        target_project = merge_request.target_project

        if target_project.approvals_before_merge.nonzero? &&
           target_project.reset_approvals_on_push &&
           merge_request.rebase_commit_sha != @newrev

          merge_request.approvals.destroy_all
        end
      end
    end

    def reset_merge_when_build_succeeds
      merge_requests_for_source_branch.each(&:reset_merge_when_build_succeeds)
    end

    def mark_pending_todos_done
      merge_requests_for_source_branch.each do |merge_request|
        todo_service.merge_request_push(merge_request, @current_user)
      end
    end

    def find_new_commits
      if branch_added?
        @commits = []

        merge_request = merge_requests_for_source_branch.first
        return unless merge_request

        begin
          # Since any number of commits could have been made to the restored branch,
          # find the common root to see what has been added.
          common_ref = @project.repository.merge_base(merge_request.diff_head_sha, @newrev)
          # If the a commit no longer exists in this repo, gitlab_git throws
          # a Rugged::OdbError. This is fixed in https://gitlab.com/gitlab-org/gitlab_git/merge_requests/52
          @commits = @project.repository.commits_between(common_ref, @newrev) if common_ref
        rescue
        end
      elsif branch_removed?
        # No commits for a deleted branch.
        @commits = []
      else
        @commits = @project.repository.commits_between(@oldrev, @newrev)
      end
    end

    # Add comment about branches being deleted or added to merge requests
    def comment_mr_branch_presence_changed
      presence = branch_added? ? :add : :delete

      merge_requests_for_source_branch.each do |merge_request|
        SystemNoteService.change_branch_presence(
          merge_request, merge_request.project, @current_user,
            :source, @branch_name, presence)
      end
    end

    # Add comment about pushing new commits to merge requests
    def comment_mr_with_commits
      return unless @commits.present?

      merge_requests_for_source_branch.each do |merge_request|
        mr_commit_ids = Set.new(merge_request.commits.map(&:id))

        new_commits, existing_commits = @commits.partition do |commit|
          mr_commit_ids.include?(commit.id)
        end

        SystemNoteService.add_commits(merge_request, merge_request.project,
                                      @current_user, new_commits,
                                      existing_commits, @oldrev)
      end
    end

    # Call merge request webhook with update branches
    def execute_mr_web_hooks
      merge_requests_for_source_branch.each do |merge_request|
        execute_hooks(merge_request, 'update')
      end
    end

    def filter_merge_requests(merge_requests)
      merge_requests.uniq.select(&:source_project)
    end

    def merge_requests_for_source_branch
      @source_merge_requests ||= begin
        merge_requests = @project.origin_merge_requests.opened.where(source_branch: @branch_name).to_a
        merge_requests += fork_merge_requests.where(source_branch: @branch_name).to_a
        filter_merge_requests(merge_requests)
      end
    end

    def fork_merge_requests
      @fork_merge_requests ||= @project.fork_merge_requests.opened
    end

    def branch_added?
      Gitlab::Git.blank_ref?(@oldrev)
    end

    def branch_removed?
      Gitlab::Git.blank_ref?(@newrev)
    end
  end
end
