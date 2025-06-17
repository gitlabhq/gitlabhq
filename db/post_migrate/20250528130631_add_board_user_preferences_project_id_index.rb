# frozen_string_literal: true

class AddBoardUserPreferencesProjectIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_board_user_preferences_on_project_id'

  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_index :board_user_preferences, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :board_user_preferences, :project_id, name: INDEX_NAME
  end
end
