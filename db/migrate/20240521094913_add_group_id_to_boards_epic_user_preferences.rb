# frozen_string_literal: true

class AddGroupIdToBoardsEpicUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :boards_epic_user_preferences, :group_id, :bigint
  end
end
