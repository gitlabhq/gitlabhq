# frozen_string_literal: true

class AddLimitToQueuedMigrationVersionInBatchedBackgroundMigrations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # 14 is set as the limit because the migration version is 14 chars in length
    add_text_limit :batched_background_migrations, :queued_migration_version, 14
  end

  def down
    remove_text_limit :batched_background_migrations, :queued_migration_version
  end
end
