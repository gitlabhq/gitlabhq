# frozen_string_literal: true

class AddCursorsToBatchedBackgroundMigrationJobs < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :batched_background_migration_jobs, :min_cursor, :jsonb, null: true
    add_column :batched_background_migration_jobs, :max_cursor, :jsonb, null: true
  end
end
