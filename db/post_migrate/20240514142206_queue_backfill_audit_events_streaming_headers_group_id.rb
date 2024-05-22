# frozen_string_literal: true

class QueueBackfillAuditEventsStreamingHeadersGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillAuditEventsStreamingHeadersGroupId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :audit_events_streaming_headers,
      :id,
      :group_id,
      :audit_events_external_audit_event_destinations,
      :namespace_id,
      :external_audit_event_destination_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :audit_events_streaming_headers,
      :id,
      [
        :group_id,
        :audit_events_external_audit_event_destinations,
        :namespace_id,
        :external_audit_event_destination_id
      ]
    )
  end
end
