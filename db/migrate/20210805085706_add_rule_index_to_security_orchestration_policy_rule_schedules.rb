# frozen_string_literal: true

class AddRuleIndexToSecurityOrchestrationPolicyRuleSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :security_orchestration_policy_rule_schedules, :rule_index, :integer, null: false, default: 0
  end
end
