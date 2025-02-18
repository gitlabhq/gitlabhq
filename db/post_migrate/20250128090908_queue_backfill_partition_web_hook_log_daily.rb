# frozen_string_literal: true

class QueueBackfillPartitionWebHookLogDaily < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillPartitionedWebHookLogsDaily'
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  TABLE_NAME = 'web_hook_logs'

  def up
    return if should_not_run?

    (max_id, max_created_at) = define_batchable_model(TABLE_NAME)
                            .order(id: :desc, created_at: :desc)
                            .pick(:id, :created_at)

    max_id ||= 0
    max_created_at ||= Time.current.to_s

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main,
      job_class_name: MIGRATION,
      job_arguments: [],
      table_name: TABLE_NAME.to_sym,
      column_name: :id,
      min_cursor: [0, 1.month.ago.to_s],
      max_cursor: [max_id, max_created_at],
      interval: DELAY_INTERVAL,
      pause_ms: 100,
      batch_class_name: STRATEGY,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      status_event: :execute
    )
  end

  def down
    return if should_not_run?

    delete_batched_background_migration(MIGRATION, TABLE_NAME.to_sym, :id, [])
  end

  private

  def should_not_run?
    Gitlab.com_except_jh?
  end
end
