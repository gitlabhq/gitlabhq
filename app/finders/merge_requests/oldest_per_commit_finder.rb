# frozen_string_literal: true

module MergeRequests
  # OldestPerCommitFinder is used to retrieve the oldest merge requests for
  # every given commit, grouped per commit SHA.
  #
  # This finder is useful when you need to efficiently retrieve the first/oldest
  # merge requests for multiple commits, and you want to do so in batches;
  # instead of running a query for every commit.
  class OldestPerCommitFinder
    def initialize(project)
      @project = project
    end

    # Returns a Hash that maps a commit ID to the oldest merge request that
    # introduced that commit.
    def execute(commits)
      id_rows = MergeRequestDiffCommit
        .oldest_merge_request_id_per_commit(@project.id, commits.map(&:id))

      mrs = MergeRequest
        .preload_target_project
        .id_in(id_rows.map { |r| r[:merge_request_id] })
        .index_by(&:id)

      id_rows.each_with_object({}) do |row, hash|
        if (mr = mrs[row[:merge_request_id]])
          hash[row[:sha]] = mr
        end
      end
    end
  end
end
