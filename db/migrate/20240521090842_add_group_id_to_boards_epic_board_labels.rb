# frozen_string_literal: true

class AddGroupIdToBoardsEpicBoardLabels < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :boards_epic_board_labels, :group_id, :bigint
  end
end
