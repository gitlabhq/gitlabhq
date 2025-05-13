# frozen_string_literal: true

class QueueBackfillResourceIterationEventsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillResourceIterationEventsNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :resource_iteration_events,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :resource_iteration_events, :id, [])
  end
end
