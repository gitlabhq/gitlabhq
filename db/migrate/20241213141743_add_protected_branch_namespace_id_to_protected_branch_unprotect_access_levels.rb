# frozen_string_literal: true

class AddProtectedBranchNamespaceIdToProtectedBranchUnprotectAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :protected_branch_unprotect_access_levels, :protected_branch_namespace_id, :bigint
  end
end
