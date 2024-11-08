# frozen_string_literal: true

class IndexBackgroundMigrationJobsOnMigrationIdAndMaxCursor < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  INDEX_NAME = 'index_migration_jobs_on_migration_id_and_cursor_max_value'

  def up
    add_concurrent_index :batched_background_migration_jobs,
      "batched_background_migration_id, max_cursor",
      where: "max_cursor is not null",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :batched_background_migration_jobs, name: INDEX_NAME
  end
end
