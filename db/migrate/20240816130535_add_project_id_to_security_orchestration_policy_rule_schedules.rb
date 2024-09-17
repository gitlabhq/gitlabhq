# frozen_string_literal: true

class AddProjectIdToSecurityOrchestrationPolicyRuleSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :security_orchestration_policy_rule_schedules, :project_id, :bigint
  end
end
