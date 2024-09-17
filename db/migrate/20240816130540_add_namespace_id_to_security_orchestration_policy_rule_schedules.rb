# frozen_string_literal: true

class AddNamespaceIdToSecurityOrchestrationPolicyRuleSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :security_orchestration_policy_rule_schedules, :namespace_id, :bigint
  end
end
