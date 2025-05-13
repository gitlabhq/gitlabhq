# frozen_string_literal: true

class AddProtectedBranchNamespaceIdToProtectedBranchPushAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    add_column :protected_branch_push_access_levels, :protected_branch_namespace_id, :bigint
  end
end
