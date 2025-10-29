# frozen_string_literal: true

class AddNotNullNotValidOnProtectedBranchPushAccessLevelsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_multi_column_not_null_constraint(
      :protected_branch_push_access_levels,
      :protected_branch_project_id, :protected_branch_namespace_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :protected_branch_push_access_levels,
      :protected_branch_project_id, :protected_branch_namespace_id
    )
  end
end
