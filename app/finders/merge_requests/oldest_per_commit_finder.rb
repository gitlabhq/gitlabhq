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
      mapping = {}
      shas = commits.map(&:id)

      # To include merge requests by the merged/merge/squash SHA, we don't need
      # to go through any diff rows.
      #
      # We can't squeeze all this into a single query, as the diff based data
      # relies on a GROUP BY. On the other hand, retrieving MRs by their merge
      # SHAs separately is much easier, and plenty fast.
      @project
        .merge_requests
        .preload_target_project
        .by_merged_or_merge_or_squash_commit_sha(shas)
        .each do |mr|
          # SHAs for merge commits, squash commits, and rebased source SHAs,
          # can't be in the merge request source branch. It _is_ possible a
          # newer merge request includes the commit, but in that case we still
          # want the oldest merge request.
          #
          # It's also possible that a merge request produces both a squashed
          # commit and a merge commit. In that case we want to store the mapping
          # for both the SHAs.
          mapping[mr.squash_commit_sha] = mr if mr.squash_commit_sha
          mapping[mr.merge_commit_sha] = mr if mr.merge_commit_sha
          mapping[mr.merged_commit_sha] = mr if mr.merged_commit_sha
        end

      remaining = shas - mapping.keys

      return mapping if remaining.empty?

      merge_requests_for_mapping(mapping, remaining)
      mapping
    end

    private

    def merge_requests_for_mapping(mapping, remaining)
      merge_request_diff_commit_rows =
        MergeRequestDiffCommit
          .oldest_merge_request_id_per_commit(@project.id, remaining)

      if Feature.enabled?(:include_generated_ref_commits_in_changelog, @project)
        generated_ref_commit_rows = GeneratedRefCommit.oldest_merge_request_id_per_commit(@project.id, remaining)
      end

      id_rows = merge_request_diff_commit_rows
      id_rows += generated_ref_commit_rows if Feature.enabled?(:include_generated_ref_commits_in_changelog, @project)

      mrs = MergeRequest
        .preload_target_project
        .id_in(id_rows.map { |r| r[:merge_request_id] })
        .index_by(&:id)

      merge_request_diff_commit_rows.each do |row|
        if (mr = mrs[row[:merge_request_id]])
          mapping[row[:sha]] = mr
        end
      end

      return unless Feature.enabled?(:include_generated_ref_commits_in_changelog, @project)

      generated_ref_commit_rows.each do |row|
        if (mr = mrs[row[:merge_request_id]])
          mapping[row[:commit_sha]] = mr
        end
      end
    end
  end
end
