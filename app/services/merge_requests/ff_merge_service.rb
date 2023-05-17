# frozen_string_literal: true

module MergeRequests
  # MergeService class
  #
  # Do git fast-forward merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do fast-forward merge via GitLab UI
  #
  class FfMergeService < MergeRequests::MergeService
    extend ::Gitlab::Utils::Override

    private

    override :execute_git_merge
    def execute_git_merge
      repository.ff_merge(
        current_user,
        source,
        merge_request.target_branch,
        merge_request: merge_request
      )
    end

    override :merge_success_data
    def merge_success_data(commit_id)
      # There is no merge commit to update, so this is just blank.
      {}
    end
  end
end
