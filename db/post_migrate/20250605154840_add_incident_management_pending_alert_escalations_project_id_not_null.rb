# frozen_string_literal: true

class AddIncidentManagementPendingAlertEscalationsProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :incident_management_pending_alert_escalations, :project_id
  end

  def down
    remove_not_null_constraint :incident_management_pending_alert_escalations, :project_id
  end
end
