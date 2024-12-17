# frozen_string_literal: true

class AddProtectedBranchProjectIdToProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :protected_branch_merge_access_levels, :protected_branch_project_id, :bigint
  end
end
