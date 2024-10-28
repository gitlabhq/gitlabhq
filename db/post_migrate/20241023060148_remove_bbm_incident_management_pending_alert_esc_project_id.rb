# frozen_string_literal: true

class RemoveBbmIncidentManagementPendingAlertEscProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillIncidentManagementPendingAlertEscalationsProjectId"

  def up
    delete_batched_background_migration(MIGRATION, :incident_management_pending_alert_escalations, :id,
      [:project_id, :alert_management_alerts, :project_id, :alert_id])
  end

  def down; end
end
