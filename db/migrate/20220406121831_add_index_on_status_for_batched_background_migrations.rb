# frozen_string_literal: true

class AddIndexOnStatusForBatchedBackgroundMigrations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_index :batched_background_migrations, :status
  end

  def down
    remove_concurrent_index_by_name :batched_background_migrations, :index_batched_background_migrations_on_status
  end
end
