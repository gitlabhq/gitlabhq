# frozen_string_literal: true

class AddApprovalGroupRulesProtectedBranchesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_group_rules_protected_branches, :namespaces, column: :group_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_group_rules_protected_branches, column: :group_id
    end
  end
end
