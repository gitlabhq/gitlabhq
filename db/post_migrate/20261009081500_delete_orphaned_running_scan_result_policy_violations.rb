# frozen_string_literal: true

class DeleteOrphanedRunningScanResultPolicyViolations < Gitlab::Database::Migration[2.4]
  milestone '19.6'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  BATCH_SIZE = 500
  RUNNING_STATUS = 0
  # updated_at, not created_at: every new pipeline re-upserts the row back to running.
  MIN_AGE = 1.day

  # Verdict-less rows with a NULL approval_policy_rule_id, which the delete path could never reach.
  # The approval rule is left in place, so the policy's required approvals still apply.
  def up
    define_batchable_model('scan_result_policy_violations')
      .where(status: RUNNING_STATUS, approval_policy_rule_id: nil, violation_data: nil)
      .where(updated_at: ...MIN_AGE.ago)
      .each_batch(of: BATCH_SIZE) { |batch| batch.delete_all }
  end

  def down
    # Irreversible. The deleted rows carried no verdict, so there is nothing to reconstruct.
  end
end
