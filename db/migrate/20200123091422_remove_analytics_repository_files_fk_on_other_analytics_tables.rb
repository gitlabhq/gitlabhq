# frozen_string_literal: true

class RemoveAnalyticsRepositoryFilesFkOnOtherAnalyticsTables < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Requires ExclusiveLock on all tables. analytics_* tables are empty
    with_lock_retries do
      remove_foreign_key_if_exists(:analytics_repository_file_edits, :analytics_repository_files) if table_exists?(:analytics_repository_file_edits) # this table might be already dropped on development environment
    end

    with_lock_retries do
      remove_foreign_key_if_exists(:analytics_repository_file_commits, :analytics_repository_files)
    end
  end

  def down
    add_concurrent_foreign_key(:analytics_repository_file_edits, :analytics_repository_files, column: :analytics_repository_file_id, on_delete: :cascade)
    add_concurrent_foreign_key(:analytics_repository_file_commits, :analytics_repository_files, column: :analytics_repository_file_id, on_delete: :cascade)
  end
end
