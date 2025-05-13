# frozen_string_literal: true

class QueueBackfillGoogleGroupAuditEventDestinationsFixed < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ORIGINAL_MIGRATION = "BackfillGoogleGroupAuditEventDestinations"
  MIGRATION = "BackfillGoogleGroupAuditEventDestinationsFixed"
  BATCH_SIZE = 100
  SUB_BATCH_SIZE = 10

  def up
    delete_batched_background_migration(ORIGINAL_MIGRATION, :audit_events_google_cloud_logging_configurations,
      :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :audit_events_google_cloud_logging_configurations,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :audit_events_google_cloud_logging_configurations, :id, [])
  end
end
