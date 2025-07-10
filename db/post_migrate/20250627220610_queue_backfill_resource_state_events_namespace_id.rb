# frozen_string_literal: true

class QueueBackfillResourceStateEventsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillResourceStateEventsNamespaceId"
  MAX_BATCH_SIZE = 50_000
  BATCH_SIZE = 30_000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      :resource_state_events,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :resource_state_events, :id, [])
  end
end
