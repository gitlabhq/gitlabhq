class RemoveUnusedCiTablesAndColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON =
    'Remove unused columns in used tables.' \
    ' Downtime required in case Rails caches them'

  def change
    %w[ci_application_settings
       ci_events
       ci_jobs
       ci_sessions
       ci_taggings
       ci_tags].each do |table|
      drop_table(table)
    end

    remove_column :ci_commits, :push_data, :text
    remove_column :ci_builds, :job_id, :integer
    remove_column :ci_builds, :deploy, :boolean
  end
end
