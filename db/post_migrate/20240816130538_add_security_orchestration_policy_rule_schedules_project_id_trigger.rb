# frozen_string_literal: true

class AddSecurityOrchestrationPolicyRuleSchedulesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    install_sharding_key_assignment_trigger(
      table: :security_orchestration_policy_rule_schedules,
      sharding_key: :project_id,
      parent_table: :security_orchestration_policy_configurations,
      parent_sharding_key: :project_id,
      foreign_key: :security_orchestration_policy_configuration_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :security_orchestration_policy_rule_schedules,
      sharding_key: :project_id,
      parent_table: :security_orchestration_policy_configurations,
      parent_sharding_key: :project_id,
      foreign_key: :security_orchestration_policy_configuration_id
    )
  end
end
