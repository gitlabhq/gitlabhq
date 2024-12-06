# frozen_string_literal: true

class IdxProtectedBranchMergeAccessLevelsOnProtectedBranchNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_protected_branch_merge_access_levels_protected_branch_names'

  def up
    add_concurrent_index :protected_branch_merge_access_levels, :protected_branch_namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :protected_branch_merge_access_levels, INDEX_NAME
  end
end
