# frozen_string_literal: true

class EnqueueBackfillMergeRequestDiffFilesPartitionedTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  TABLE = :merge_request_diff_files
  MIGRATION = "BackfillMergeRequestFileDiffsPartitionedTable"
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 200

  def up
    (max_id, max_order) = define_batchable_model(TABLE)
      .order(merge_request_diff_id: :desc, relative_order: :desc)
      .pick(:merge_request_diff_id, :relative_order)

    max_id ||= 0
    max_order ||= 0

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main_org,
      job_class_name: MIGRATION,
      job_arguments: [
        :merge_request_diff_files_99208b8fac,
        :merge_request_diff_id,
        :relative_order
      ],
      table_name: TABLE,
      column_name: :merge_request_diff_id,
      min_cursor: [0, 0],
      max_cursor: [max_id, max_order],
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
      TABLE,
      :merge_request_diff_id,
      [:merge_request_diff_files_99208b8fac, :merge_request_diff_id, :relative_order]
    )
  end
end
