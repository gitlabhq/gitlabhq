# frozen_string_literal: true

class AddProtectedBranchMergeAccessLevelsMultiColumnNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_multi_column_not_null_constraint :protected_branch_merge_access_levels, :protected_branch_project_id,
      :protected_branch_namespace_id
  end

  def down
    remove_multi_column_not_null_constraint :protected_branch_merge_access_levels, :protected_branch_project_id,
      :protected_branch_namespace_id
  end
end
