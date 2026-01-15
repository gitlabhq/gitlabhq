# frozen_string_literal: true

class FinalizeBackfillExternalInstanceAuditEventDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillExternalInstanceAuditEventDestinations',
      table_name: :audit_events_instance_external_audit_event_destinations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
