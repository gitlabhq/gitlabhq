# frozen_string_literal: true

class AddUsersForeignKeyToBoardUserPreferences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :board_user_preferences, :users, column: :user_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :board_user_preferences, column: :user_id
    end
  end
end
