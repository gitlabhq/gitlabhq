# frozen_string_literal: true

class EpicBoardsShowColors < Gitlab::Database::Migration[2.1]
  def change
    add_column :boards_epic_boards, :display_colors, :boolean, default: true, null: false
  end
end
