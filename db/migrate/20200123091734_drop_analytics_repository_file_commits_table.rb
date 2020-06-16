# frozen_string_literal: true

class DropAnalyticsRepositoryFileCommitsTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # Requires ExclusiveLock on the table. Not in use, no records, no FKs.
    # rubocop:disable Migration/DropTable
    drop_table :analytics_repository_file_commits
    # rubocop:enable Migration/DropTable
  end

  def down
    create_table :analytics_repository_file_commits do |t|
      t.bigint :analytics_repository_file_id, null: false
      t.index :analytics_repository_file_id, name: 'index_analytics_repository_file_commits_file_id'
      t.bigint :project_id, null: false
      t.date :committed_date, null: false
      t.integer :commit_count, limit: 2, null: false
    end

    add_index :analytics_repository_file_commits,
      [:project_id, :committed_date, :analytics_repository_file_id],
      name: 'index_file_commits_on_committed_date_file_id_and_project_id',
      unique: true
  end
end
