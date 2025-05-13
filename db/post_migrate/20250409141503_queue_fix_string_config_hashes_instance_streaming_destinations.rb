# frozen_string_literal: true

class QueueFixStringConfigHashesInstanceStreamingDestinations < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "FixStringConfigHashesInstanceStreamingDestinations"
  BATCH_SIZE = 100
  SUB_BATCH_SIZE = 10

  def up
    queue_batched_background_migration(
      MIGRATION,
      :audit_events_instance_external_streaming_destinations,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :audit_events_instance_external_streaming_destinations, :id, [])
  end
end
