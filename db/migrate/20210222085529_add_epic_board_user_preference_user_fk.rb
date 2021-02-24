# frozen_string_literal: true

class AddEpicBoardUserPreferenceUserFk < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :boards_epic_list_user_preferences, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :boards_epic_list_user_preferences, :users
    end
  end
end
