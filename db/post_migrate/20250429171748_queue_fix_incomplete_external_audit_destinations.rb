# frozen_string_literal: true

class QueueFixIncompleteExternalAuditDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "FixIncompleteExternalAuditDestinations"
  BATCH_SIZE = 100
  SUB_BATCH_SIZE = 10

  def up
    queue_batched_background_migration(
      MIGRATION,
      :audit_events_external_audit_event_destinations,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :audit_events_external_audit_event_destinations, :id, [])
  end
end
