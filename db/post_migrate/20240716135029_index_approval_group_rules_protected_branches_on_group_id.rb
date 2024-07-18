# frozen_string_literal: true

class IndexApprovalGroupRulesProtectedBranchesOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_group_rules_protected_branches_on_group_id'

  def up
    add_concurrent_index :approval_group_rules_protected_branches, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_group_rules_protected_branches, INDEX_NAME
  end
end
