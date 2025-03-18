# frozen_string_literal: true

class QueueBackfillMergeRequestContextCommitDiffFilesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillMergeRequestContextCommitDiffFilesProjectId"
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    model = define_batchable_model('merge_request_context_commit_diff_files')
    max_merge_request_context_commit_id = model.maximum(:merge_request_context_commit_id)
    max_relative_order = model.maximum(:relative_order)

    max_merge_request_context_commit_id ||= 0
    max_relative_order ||= 0

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main_cell,
      job_class_name: MIGRATION,
      job_arguments: [
        :project_id,
        :merge_request_context_commits,
        :project_id,
        :merge_request_context_commit_id
      ],
      table_name: :merge_request_context_commit_diff_files,
      column_name: :merge_request_context_commit_id,
      min_cursor: [0, 0],
      max_cursor: [max_merge_request_context_commit_id, max_relative_order],
      interval: DELAY_INTERVAL,
      pause_ms: 100,
      batch_class_name: STRATEGY,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      status_event: :execute
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :merge_request_context_commit_diff_files,
      :merge_request_context_commit_id,
      [
        :project_id,
        :merge_request_context_commits,
        :project_id,
        :merge_request_context_commit_id
      ]
    )
  end
end
