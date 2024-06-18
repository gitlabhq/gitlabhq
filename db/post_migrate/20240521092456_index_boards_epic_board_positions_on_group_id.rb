# frozen_string_literal: true

class IndexBoardsEpicBoardPositionsOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_boards_epic_board_positions_on_group_id'

  def up
    add_concurrent_index :boards_epic_board_positions, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :boards_epic_board_positions, INDEX_NAME
  end
end
