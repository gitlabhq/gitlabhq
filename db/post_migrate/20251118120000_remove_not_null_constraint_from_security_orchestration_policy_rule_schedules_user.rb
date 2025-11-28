# frozen_string_literal: true

class RemoveNotNullConstraintFromSecurityOrchestrationPolicyRuleSchedulesUser < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  disable_ddl_transaction!

  def up
    change_column_null :security_orchestration_policy_rule_schedules, :user_id, true
  end

  def down
    # Note: This may fail if there are NULL values in the column.
    # Make sure to rollback CleanupSecurityOrchestrationPolicyRuleSchedulesWithNullUserId before this migration
    change_column_null :security_orchestration_policy_rule_schedules, :user_id, false
  end
end
