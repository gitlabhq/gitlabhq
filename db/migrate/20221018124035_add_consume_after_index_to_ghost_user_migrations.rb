# frozen_string_literal: true

class AddConsumeAfterIndexToGhostUserMigrations < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_ghost_user_migrations_on_consume_after_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ghost_user_migrations, [:consume_after, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ghost_user_migrations, INDEX_NAME
  end
end
