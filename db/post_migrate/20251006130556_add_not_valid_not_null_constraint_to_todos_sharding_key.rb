# frozen_string_literal: true

class AddNotValidNotNullConstraintToTodosShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_multi_column_not_null_constraint(
      :todos,
      :organization_id, :group_id, :project_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :todos,
      :organization_id, :group_id, :project_id
    )
  end
end
