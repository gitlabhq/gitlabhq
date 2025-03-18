# frozen_string_literal: true

class AddMergeRequestsApprovalRulesUsersApprovalRuleFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_requests_approval_rules_approver_users, :merge_requests_approval_rules,
      column: :approval_rule_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_requests_approval_rules_approver_users, column: :approval_rule_id
    end
  end
end
