module MergeRequests
  # MergeService class
  #
  # Do git fast-forward merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do fast-forward merge via GitLab UI
  #
  class FfMergeService < MergeRequests::MergeService
    private

    def commit
      repository.ff_merge(current_user, merge_request.diff_head_sha, merge_request.target_branch)
    end
  end
end
