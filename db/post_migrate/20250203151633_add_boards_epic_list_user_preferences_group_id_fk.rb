# frozen_string_literal: true

class AddBoardsEpicListUserPreferencesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :boards_epic_list_user_preferences, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :boards_epic_list_user_preferences, column: :group_id
    end
  end
end
