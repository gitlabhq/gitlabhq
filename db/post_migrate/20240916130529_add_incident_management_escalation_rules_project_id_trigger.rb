# frozen_string_literal: true

class AddIncidentManagementEscalationRulesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :incident_management_escalation_rules,
      sharding_key: :project_id,
      parent_table: :incident_management_escalation_policies,
      parent_sharding_key: :project_id,
      foreign_key: :policy_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :incident_management_escalation_rules,
      sharding_key: :project_id,
      parent_table: :incident_management_escalation_policies,
      parent_sharding_key: :project_id,
      foreign_key: :policy_id
    )
  end
end
