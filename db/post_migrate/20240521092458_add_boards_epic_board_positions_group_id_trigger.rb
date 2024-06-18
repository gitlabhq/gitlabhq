# frozen_string_literal: true

class AddBoardsEpicBoardPositionsGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :boards_epic_board_positions,
      sharding_key: :group_id,
      parent_table: :boards_epic_boards,
      parent_sharding_key: :group_id,
      foreign_key: :epic_board_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :boards_epic_board_positions,
      sharding_key: :group_id,
      parent_table: :boards_epic_boards,
      parent_sharding_key: :group_id,
      foreign_key: :epic_board_id
    )
  end
end
