# frozen_string_literal: true

class IndexProtectedBranchPushAccessLevelsOnProtectedBranchProjectId < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_protected_branch_push_access_levels_on_protected_branch_p'

  def up
    add_concurrent_index :protected_branch_push_access_levels, :protected_branch_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :protected_branch_push_access_levels, INDEX_NAME
  end
end
