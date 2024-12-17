# frozen_string_literal: true

class AddProtectedBranchNamespaceIdToProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :protected_branch_merge_access_levels, :protected_branch_namespace_id, :bigint
  end
end
