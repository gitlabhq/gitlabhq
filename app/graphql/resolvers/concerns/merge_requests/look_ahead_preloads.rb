# frozen_string_literal: true

module MergeRequests
  module LookAheadPreloads
    extend ActiveSupport::Concern

    prepended do
      include ::LooksAhead
    end

    private

    def unconditional_includes
      [:target_project, :author]
    end

    def preloads
      {
        assignees: [:assignees],
        award_emoji: { award_emoji: [:awardable] },
        reviewers: [:reviewers],
        participants: MergeRequest.participant_includes,
        author: [:author],
        merged_at: [:metrics],
        closed_at: [:metrics],
        commit_count: [:metrics],
        diff_stats_summary: [:metrics],
        approved_by: [:approved_by_users],
        merge_after: [:merge_schedule],
        mergeable: [:merge_schedule],
        detailed_merge_status: [:merge_schedule],
        milestone: [:milestone],
        security_auto_fix: [:author],
        head_pipeline: [:merge_request_diff, { head_pipeline: [:merge_request, :project] }],
        timelogs: [:timelogs],
        pipelines: [:merge_request_diffs], # used by `recent_diff_head_shas` to load pipelines
        committers: [merge_request_diff: [:merge_request_diff_commits]],
        suggested_reviewers: [:predictions],
        diff_stats: [latest_merge_request_diff: [:merge_request_diff_commits]],
        source_branch_exists: [:source_project, { source_project: [:route] }]
      }
    end
  end
end
