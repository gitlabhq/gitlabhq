class RemoveMergeRequestDiffStCommitsAndStDiffs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :merge_request_diffs, :st_commits, :text
    remove_column :merge_request_diffs, :st_diffs, :text
  end
end
