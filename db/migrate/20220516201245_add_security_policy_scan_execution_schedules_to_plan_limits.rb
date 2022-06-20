# frozen_string_literal: true

class AddSecurityPolicyScanExecutionSchedulesToPlanLimits < Gitlab::Database::Migration[2.0]
  def up
    add_column(:plan_limits, :security_policy_scan_execution_schedules, :integer, default: 0, null: false)
  end

  def down
    remove_column(:plan_limits, :security_policy_scan_execution_schedules)
  end
end
