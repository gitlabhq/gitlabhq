# frozen_string_literal: true

class AddQueuedMigrationVersionToBatchedBackgroundMigrations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_batched_background_migrations_queued_migration_version'

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230921082223_add_limit_to_queued_migration_version_in_batched_background_migrations.rb
  def up
    add_column(:batched_background_migrations, :queued_migration_version, :text, if_not_exists: true)

    add_concurrent_index(
      :batched_background_migrations,
      :queued_migration_version,
      unique: true,
      name: INDEX_NAME
    )
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column(:batched_background_migrations, :queued_migration_version, :text, if_exists: true)
  end
end
