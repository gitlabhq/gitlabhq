# frozen_string_literal: true

class AddPolicyTypeToSecurityOrchestrationPolicyRuleSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :security_orchestration_policy_rule_schedules, :policy_type, :integer, limit: 2, default: 0, null: false
  end
end
