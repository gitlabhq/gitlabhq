# frozen_string_literal: true

class AddMemberRoleIdToProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :protected_branch_merge_access_levels, :member_role_id, :bigint
  end
end
