# frozen_string_literal: true

class CleanupSecurityOrchestrationPolicyRuleSchedulesWithNullUserId < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  class SecurityOrchestrationPolicyRuleSchedule < MigrationRecord
    include EachBatch

    self.table_name = 'security_orchestration_policy_rule_schedules'
  end

  def up
    # no-op - this migration is required to allow a rollback of
    # `RemoveNotNullConstraintFromSecurityOrchestrationPolicyRuleSchedulesUserId`
  end

  def down
    # Remove records with NULL user_id before re-adding the NOT NULL constraint
    SecurityOrchestrationPolicyRuleSchedule.each_batch(of: BATCH_SIZE) do |relation|
      relation.where(user_id: nil).delete_all
    end
  end
end
