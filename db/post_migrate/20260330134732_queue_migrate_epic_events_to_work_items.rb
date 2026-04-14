# frozen_string_literal: true

class QueueMigrateEpicEventsToWorkItems < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "MigrateEpicEventsToWorkItems"
  BATCH_SIZE = 300
  SUB_BATCH_SIZE = 50
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :epics,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :epics, :id, [])
  end
end
