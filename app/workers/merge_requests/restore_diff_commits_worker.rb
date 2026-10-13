# frozen_string_literal: true

module MergeRequests
  # Restores merge_request_diff_commits rows that the partitioning backfill
  # skipped, copying them back from the archived table for one diff. Scheduled
  # from MergeRequestDiff when a read finds no rows for a diff with commits.
  class RestoreDiffCommitsWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :code_review_workflow
    urgency :low
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    defer_on_database_health_signal :gitlab_main_org, [:merge_request_diff_commits], 1.minute

    # The block says whether the read found no rows and only runs once the flag
    # is on, so with the flag off nothing else runs. A diff whose rows were lost
    # keeps its commits_count, since that column was set from the rows when they
    # were written. Reads inside a transaction are skipped, since the next read
    # outside one will catch it. Enqueues at most once per request.
    def self.schedule_for(merge_request_diff)
      project_id = merge_request_diff.project_id

      return unless Feature.enabled?(:restore_missing_mr_diff_commits, Project.actor_from_id(project_id))
      return unless yield
      return unless project_id && merge_request_diff.commits_count.to_i > 0
      return unless merge_request_diff.read_new_commits_table?
      return if MergeRequestDiff.inside_transaction?

      Gitlab::SafeRequestStore.fetch([:restore_missing_mr_diff_commits, merge_request_diff.id]) do
        perform_async(merge_request_diff.id)
        true
      end
    end

    def perform(merge_request_diff_id)
      diff = MergeRequestDiff.find_by_id(merge_request_diff_id)
      return unless diff&.project_id
      return unless Feature.enabled?(:restore_missing_mr_diff_commits, Project.actor_from_id(diff.project_id))
      return unless MergeRequestDiffCommit.archived_table_exists?
      return if diff.merge_request_diff_commits.exists?

      inserted = MergeRequestDiffCommit.restore_from_archived(diff.id)

      log_extra_metadata_on_done(:merge_request_diff_id, diff.id)
      log_extra_metadata_on_done(:commits_count, diff.commits_count)
      log_extra_metadata_on_done(:inserted_rows, inserted)
    end
  end
end
