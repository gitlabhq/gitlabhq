# frozen_string_literal: true

class AddEpicBoardPositionIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_boards_epic_board_positions_on_scoped_relative_position'

  disable_ddl_transaction!

  def up
    add_concurrent_index :boards_epic_board_positions, [:epic_board_id, :epic_id, :relative_position], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :boards_epic_board_positions, INDEX_NAME
  end
end
