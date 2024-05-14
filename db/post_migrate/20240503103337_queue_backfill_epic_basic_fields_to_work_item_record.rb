# frozen_string_literal: true

class QueueBackfillEpicBasicFieldsToWorkItemRecord < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  MIGRATION = "BackfillEpicBasicFieldsToWorkItemRecord"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 50
  # not passing any group id, means we'd backfill everything. We still have the option to pass in a group id if we
  # need to reschedule the backfilling for a single group
  GROUP_ID = nil

  def up
    queue_batched_background_migration(
      MIGRATION,
      :epics,
      batching_column,
      GROUP_ID,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :epics, batching_column, [GROUP_ID])
  end

  def batching_column
    GROUP_ID.present? ? :iid : :id
  end
end
