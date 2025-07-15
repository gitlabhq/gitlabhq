# frozen_string_literal: true

class AddBoardsEpicListUserPreferencesGroupIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :boards_epic_list_user_preferences, :group_id
  end

  def down
    remove_not_null_constraint :boards_epic_list_user_preferences, :group_id
  end
end
