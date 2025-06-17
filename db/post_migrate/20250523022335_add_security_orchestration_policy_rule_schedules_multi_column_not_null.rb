# frozen_string_literal: true

class AddSecurityOrchestrationPolicyRuleSchedulesMultiColumnNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_multi_column_not_null_constraint :security_orchestration_policy_rule_schedules, :project_id, :namespace_id
  end

  def down
    remove_multi_column_not_null_constraint :security_orchestration_policy_rule_schedules, :project_id, :namespace_id
  end
end
