module MergeRequests
  class RefreshService < MergeRequests::BaseService
    def execute(oldrev, newrev, ref)
      return true unless Gitlab::Git.branch_ref?(ref)

      @oldrev, @newrev = oldrev, newrev
      @branch_name = Gitlab::Git.ref_name(ref)
      @fork_merge_requests = @project.fork_merge_requests.opened
      @commits = @project.repository.commits_between(oldrev, newrev)

      close_merge_requests
      reload_merge_requests
      execute_mr_web_hooks
      comment_mr_with_commits

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
      merge_requests = merge_requests.select(&:last_commit)

      merge_requests = merge_requests.select do |merge_request|
        commit_ids.include?(merge_request.last_commit.id)
      end


      merge_requests.uniq.select(&:source_project).each do |merge_request|
        MergeRequests::PostMergeService.
          new(merge_request.target_project, @current_user).
          execute(merge_request)
      end
    end

    def force_push?
      Gitlab::ForcePushCheck.force_push?(@project, @oldrev, @newrev)
    end

    # Refresh merge request diff if we push to source or target branch of merge request
    # Note: we should update merge requests from forks too
    def reload_merge_requests
      merge_requests = @project.merge_requests.opened.by_branch(@branch_name).to_a
      merge_requests += @fork_merge_requests.by_branch(@branch_name).to_a
      merge_requests = filter_merge_requests(merge_requests)

      merge_requests.each do |merge_request|

        if merge_request.source_branch == @branch_name || force_push?
          merge_request.reload_code
          merge_request.mark_as_unchecked
        else
          mr_commit_ids = merge_request.commits.map(&:id)
          push_commit_ids = @commits.map(&:id)
          matches = mr_commit_ids & push_commit_ids

          if matches.any?
            merge_request.reload_code
            merge_request.mark_as_unchecked
          else
            merge_request.mark_as_unchecked
          end
        end
      end
    end

    # Add comment about pushing new commits to merge requests
    def comment_mr_with_commits
      merge_requests = @project.origin_merge_requests.opened.where(source_branch: @branch_name).to_a
      merge_requests += @fork_merge_requests.where(source_branch: @branch_name).to_a
      merge_requests = filter_merge_requests(merge_requests)

      merge_requests.each do |merge_request|
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
      merge_requests = @project.origin_merge_requests.opened
        .where(source_branch: @branch_name)
        .to_a
      merge_requests += @fork_merge_requests.where(source_branch: @branch_name)
        .to_a
      merge_requests = filter_merge_requests(merge_requests)

      merge_requests.each do |merge_request|
        execute_hooks(merge_request, 'update')
      end
    end

    def filter_merge_requests(merge_requests)
      merge_requests.uniq.select(&:source_project)
    end
  end
end
