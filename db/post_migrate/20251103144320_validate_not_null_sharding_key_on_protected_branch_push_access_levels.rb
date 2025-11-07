# frozen_string_literal: true

class ValidateNotNullShardingKeyOnProtectedBranchPushAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = :check_2b64375289

  def up
    validate_multi_column_not_null_constraint(
      :protected_branch_push_access_levels,
      :protected_branch_namespace_id,
      :protected_branch_project_id,
      constraint_name: CONSTRAINT_NAME
    )
  end

  def down
    # no-op
  end
end
