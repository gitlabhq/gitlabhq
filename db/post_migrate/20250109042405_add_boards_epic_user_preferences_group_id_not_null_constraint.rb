# frozen_string_literal: true

class AddBoardsEpicUserPreferencesGroupIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :boards_epic_user_preferences, :group_id
  end

  def down
    remove_not_null_constraint :boards_epic_user_preferences, :group_id
  end
end
