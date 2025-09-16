# frozen_string_literal: true

class FinalizeBackfillIncidentManagementPendingAlertEscProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIncidentManagementPendingAlertEscalationsProjectId',
      table_name: :incident_management_pending_alert_escalations,
      column_name: :id,
      job_arguments: [:project_id, :alert_management_alerts, :project_id, :alert_id],
      finalize: true
    )
  end

  def down
    # This is an empty down migration.
    # Batched background migrations are not reversed automatically.
  end
end
