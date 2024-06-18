# frozen_string_literal: true

class DropIndexBoardsEpicUserPreferencesOnBoardId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  TABLE_NAME = :boards_epic_user_preferences
  INDEX_NAME = :index_boards_epic_user_preferences_on_board_id
  COLUMN_NAMES = [:board_id]

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
