# frozen_string_literal: true

class AddBoardsForeignKeyToBoardUserPreferences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :board_user_preferences, :boards, column: :board_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :board_user_preferences, column: :board_id
    end
  end
end
