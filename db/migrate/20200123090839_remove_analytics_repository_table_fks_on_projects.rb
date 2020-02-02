# frozen_string_literal: true

class RemoveAnalyticsRepositoryTableFksOnProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # Requires ExclusiveLock on all tables. analytics_* tables are empty
      remove_foreign_key :analytics_repository_files, :projects
      remove_foreign_key :analytics_repository_file_edits, :projects if table_exists?(:analytics_repository_file_edits) # this table might be already dropped on development environment
      remove_foreign_key :analytics_repository_file_commits, :projects
    end
  end

  def down
    with_lock_retries do
      # rubocop:disable Migration/AddConcurrentForeignKey
      add_foreign_key :analytics_repository_files, :projects, on_delete: :cascade
      add_foreign_key :analytics_repository_file_edits, :projects, on_delete: :cascade
      add_foreign_key :analytics_repository_file_commits, :projects, on_delete: :cascade
      # rubocop:enable Migration/AddConcurrentForeignKey
    end
  end
end
