class RenameCiCommitsToCiPipelines < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Rename table ci_commits to ci_pipelines'

  def change
    rename_table 'ci_commits', 'ci_pipelines'
  end
end
