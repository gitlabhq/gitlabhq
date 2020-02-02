# frozen_string_literal: true

class RemoveAnalyticsRepositoryFilesFkOnOtherAnalyticsTables < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # Requires ExclusiveLock on all tables. analytics_* tables are empty
      remove_foreign_key :analytics_repository_file_edits, :analytics_repository_files if table_exists?(:analytics_repository_file_edits) # this table might be already dropped on development environment
      remove_foreign_key :analytics_repository_file_commits, :analytics_repository_files
    end
  end

  def down
    with_lock_retries do
      # rubocop:disable Migration/AddConcurrentForeignKey
      add_foreign_key :analytics_repository_file_edits, :analytics_repository_files, on_delete: :cascade
      add_foreign_key :analytics_repository_file_commits, :analytics_repository_files, on_delete: :cascade
      # rubocop:enable Migration/AddConcurrentForeignKey
    end
  end
end
