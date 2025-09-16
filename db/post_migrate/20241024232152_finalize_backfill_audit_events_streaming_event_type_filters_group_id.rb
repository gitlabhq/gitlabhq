# frozen_string_literal: true

class FinalizeBackfillAuditEventsStreamingEventTypeFiltersGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillAuditEventsStreamingEventTypeFiltersGroupId',
      table_name: :audit_events_streaming_event_type_filters,
      column_name: :id,
      job_arguments: [:group_id, :audit_events_external_audit_event_destinations, :namespace_id,
        :external_audit_event_destination_id],
      finalize: true
    )
  end

  def down; end
end
