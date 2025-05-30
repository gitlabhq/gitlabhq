# frozen_string_literal: true

class AddBoardUserPreferencesGroupIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_board_user_preferences_on_group_id'

  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_index :board_user_preferences, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :board_user_preferences, :group_id, name: INDEX_NAME
  end
end
