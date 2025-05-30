# frozen_string_literal: true

class AddBoardUserPreferencesProjectIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :board_user_preferences,
      :projects,
      column: :project_id,
      target_column: :id,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :board_user_preferences, column: :project_id
    end
  end
end
