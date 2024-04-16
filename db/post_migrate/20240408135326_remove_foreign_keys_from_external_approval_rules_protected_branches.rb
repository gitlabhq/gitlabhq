# frozen_string_literal: true

class RemoveForeignKeysFromExternalApprovalRulesProtectedBranches < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :external_approval_rules_protected_branches, :external_approval_rules
      remove_foreign_key :external_approval_rules_protected_branches, :protected_branches
    end
  end

  def down
    add_concurrent_foreign_key :external_approval_rules_protected_branches,
      :external_approval_rules, column: :external_approval_rule_id, on_delete: :cascade
    add_concurrent_foreign_key :external_approval_rules_protected_branches,
      :protected_branches, column: :protected_branch_id, on_delete: :cascade
  end
end
