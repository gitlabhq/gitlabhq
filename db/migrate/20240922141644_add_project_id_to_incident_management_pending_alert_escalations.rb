# frozen_string_literal: true

class AddProjectIdToIncidentManagementPendingAlertEscalations < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :incident_management_pending_alert_escalations, :project_id, :bigint
  end
end
