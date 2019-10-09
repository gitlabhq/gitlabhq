# frozen_string_literal: true

class CreateAnalyticsRepositoryFileCommits < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :analytics_repository_file_commits do |t|
      t.references :analytics_repository_file, index: { name: 'index_analytics_repository_file_commits_file_id' }, foreign_key: { on_delete: :cascade }, null: false
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.date :committed_date, null: false
      t.integer :commit_count, limit: 2, null: false
    end

    add_index :analytics_repository_file_commits,
      [:project_id, :committed_date, :analytics_repository_file_id],
      name: 'index_file_commits_on_committed_date_file_id_and_project_id',
      unique: true
  end
end
