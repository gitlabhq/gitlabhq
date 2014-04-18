class MigrateMrDiffs < ActiveRecord::Migration
  def self.up
    execute "INSERT INTO merge_request_diffs ( merge_request_id, st_commits, st_diffs ) SELECT id, st_commits, st_diffs FROM merge_requests"
  end

  def self.down
    MergeRequestDiff.delete_all
  end
end
