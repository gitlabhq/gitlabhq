# frozen_string_literal: true

class AddBoardUserPreferencesShardingKeyNotNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_multi_column_not_null_constraint(:board_user_preferences, :group_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:board_user_preferences, :group_id, :project_id)
  end
end
