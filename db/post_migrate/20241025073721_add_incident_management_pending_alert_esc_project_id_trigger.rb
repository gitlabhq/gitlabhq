# frozen_string_literal: true

class AddIncidentManagementPendingAlertEscProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    install_sharding_key_assignment_trigger(
      table: :incident_management_pending_alert_escalations,
      sharding_key: :project_id,
      parent_table: :alert_management_alerts,
      parent_sharding_key: :project_id,
      foreign_key: :alert_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :incident_management_pending_alert_escalations,
      sharding_key: :project_id,
      parent_table: :alert_management_alerts,
      parent_sharding_key: :project_id,
      foreign_key: :alert_id
    )
  end
end
