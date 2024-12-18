# frozen_string_literal: true

class AddProtectedBranchProjectIdToProtectedBranchUnprotectAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :protected_branch_unprotect_access_levels, :protected_branch_project_id, :bigint
  end
end
