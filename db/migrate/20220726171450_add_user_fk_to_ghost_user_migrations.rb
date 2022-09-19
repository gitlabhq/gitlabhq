# frozen_string_literal: true

class AddUserFkToGhostUserMigrations < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ghost_user_migrations, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ghost_user_migrations, column: :user_id
    end
  end
end
