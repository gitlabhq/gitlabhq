# frozen_string_literal: true

class AddFkToApprovalRulesOnScanResultPolicyId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_project_rules,
      :scan_result_policies,
      column: :scan_result_policy_id,
      on_delete: :cascade,
      reverse_lock_order: true
    add_concurrent_foreign_key :approval_merge_request_rules,
      :scan_result_policies,
      column: :scan_result_policy_id,
      on_delete: :cascade,
      reverse_lock_order: true
  end

  def down
    remove_foreign_key_if_exists :approval_project_rules, column: :scan_result_policy_id
    remove_foreign_key_if_exists :approval_merge_request_rules, column: :scan_result_policy_id
  end
end
