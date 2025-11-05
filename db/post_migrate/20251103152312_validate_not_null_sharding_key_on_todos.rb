# frozen_string_literal: true

class ValidateNotNullShardingKeyOnTodos < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = :check_3c13ed1c7a

  def up
    validate_multi_column_not_null_constraint(
      :todos,
      :organization_id, :group_id, :project_id,
      constraint_name: CONSTRAINT_NAME
    )
  end

  def down
    # no-op
  end
end
