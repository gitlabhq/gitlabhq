# frozen_string_literal: true

class ReplaceFkOnApprovalMergeRequestRulesScanResultPolicyId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  NEW_CONSTRAINT_NAME = 'fk_approval_merge_request_rules_on_scan_result_policy_id'

  def up
    add_concurrent_foreign_key(
      :approval_merge_request_rules,
      :scan_result_policies,
      column: :scan_result_policy_id,
      on_delete: :nullify,
      validate: false,
      name: NEW_CONSTRAINT_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:approval_merge_request_rules,
        column: :scan_result_policy_id,
        on_delete: :nullify,
        name: NEW_CONSTRAINT_NAME)
    end
  end
end
