# frozen_string_literal: true

class IndexBoardsEpicUserPreferencesOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_boards_epic_user_preferences_on_group_id'

  def up
    add_concurrent_index :boards_epic_user_preferences, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :boards_epic_user_preferences, INDEX_NAME
  end
end
