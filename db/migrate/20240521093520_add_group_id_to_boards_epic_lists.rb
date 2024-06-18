# frozen_string_literal: true

class AddGroupIdToBoardsEpicLists < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :boards_epic_lists, :group_id, :bigint
  end
end
