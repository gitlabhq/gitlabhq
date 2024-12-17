# frozen_string_literal: true

module MergeRequests
  class MergeRequestDiffComparison
    def initialize(merge_request_diff)
      @merge_request_diff = merge_request_diff
      @project = merge_request_diff.project
    end

    def compare_with(sha)
      # When compare merge request versions we want diff A..B instead of A...B
      # so we handle cases when user does squash and rebase of the commits between versions.
      # For this reason we set straight to true by default.
      CompareService
        .new(project, merge_request_diff.head_commit_sha)
        .execute(project, sha, straight: true)
    end

    private

    attr_reader :merge_request_diff, :project
  end
end
