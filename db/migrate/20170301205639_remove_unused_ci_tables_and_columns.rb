class RemoveUnusedCiTablesAndColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    %w[ci_application_settings
       ci_events
       ci_jobs
       ci_sessions
       ci_taggings
       ci_tags].each do |table|
      drop_table(table)
    end

    remove_column :ci_commits, :push_data
    remove_column :ci_builds, :job_id
    remove_column :ci_builds, :deploy
  end
end
