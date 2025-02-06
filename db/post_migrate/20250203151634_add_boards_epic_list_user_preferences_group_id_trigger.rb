# frozen_string_literal: true

class AddBoardsEpicListUserPreferencesGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :boards_epic_list_user_preferences,
      sharding_key: :group_id,
      parent_table: :boards_epic_lists,
      parent_sharding_key: :group_id,
      foreign_key: :epic_list_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :boards_epic_list_user_preferences,
      sharding_key: :group_id,
      parent_table: :boards_epic_lists,
      parent_sharding_key: :group_id,
      foreign_key: :epic_list_id
    )
  end
end
