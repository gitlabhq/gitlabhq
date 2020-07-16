# frozen_string_literal: true

class AddBackgroundMigrationJobIndexForPartitioningMigrations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  INDEX_NAME = 'index_background_migration_jobs_for_partitioning_migrations'

  def up
    # rubocop:disable Migration/AddIndex
    add_index :background_migration_jobs, '((arguments ->> 2))', name: INDEX_NAME,
      where: "class_name = 'Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable'"
    # rubocop:enable Migration/AddIndex
  end

  def down
    remove_index :background_migration_jobs, name: INDEX_NAME # rubocop:disable Migration/RemoveIndex
  end
end
