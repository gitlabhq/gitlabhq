# frozen_string_literal: true

class AddIndexMemberRoleIdToProtectedBranchAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  INDEX_MERGE = 'index_protected_branch_merge_access_levels_on_member_role_id'
  INDEX_PUSH = 'index_protected_branch_push_access_levels_on_member_role_id'
  INDEX_UNPROTECT = 'idx_protected_branch_unprotect_access_levels_on_member_role_id'

  def up
    add_concurrent_index :protected_branch_merge_access_levels, :member_role_id, name: INDEX_MERGE
    add_concurrent_index :protected_branch_push_access_levels, :member_role_id, name: INDEX_PUSH
    add_concurrent_index :protected_branch_unprotect_access_levels, :member_role_id, name: INDEX_UNPROTECT
  end

  def down
    remove_concurrent_index_by_name :protected_branch_merge_access_levels, INDEX_MERGE
    remove_concurrent_index_by_name :protected_branch_push_access_levels, INDEX_PUSH
    remove_concurrent_index_by_name :protected_branch_unprotect_access_levels, INDEX_UNPROTECT
  end
end
