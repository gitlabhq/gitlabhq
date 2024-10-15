# frozen_string_literal: true

class AddProjectIdToIncidentManagementEscalationRules < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :incident_management_escalation_rules, :project_id, :bigint
  end
end
