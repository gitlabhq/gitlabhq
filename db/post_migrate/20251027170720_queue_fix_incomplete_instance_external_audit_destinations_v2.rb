# frozen_string_literal: true

class QueueFixIncompleteInstanceExternalAuditDestinationsV2 < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "FixIncompleteInstanceExternalAuditDestinationsV2"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(
      'FixIncompleteInstanceExternalAuditDestinations',
      :audit_events_instance_external_audit_event_destinations,
      :id,
      []
    )
    queue_batched_background_migration(
      MIGRATION,
      :audit_events_instance_external_audit_event_destinations,
      :id,
      job_interval: 2.minutes,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :audit_events_instance_external_audit_event_destinations, :id, [])
  end
end
