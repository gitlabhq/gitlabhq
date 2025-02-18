# frozen_string_literal: true

class AddGroupIdToBoardsEpicListUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :boards_epic_list_user_preferences, :group_id, :bigint
  end
end
