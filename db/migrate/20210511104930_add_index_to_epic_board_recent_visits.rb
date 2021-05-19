# frozen_string_literal: true

class AddIndexToEpicBoardRecentVisits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_epic_board_recent_visits_on_user_group_and_board'

  disable_ddl_transaction!

  def up
    add_concurrent_index :boards_epic_board_recent_visits,
                         [:user_id, :group_id, :epic_board_id],
                         name: INDEX_NAME,
                         unique: true
  end

  def down
    remove_concurrent_index_by_name :boards_epic_board_recent_visits, INDEX_NAME
  end
end
