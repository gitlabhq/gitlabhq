class MigrateMrDiffs < ActiveRecord::Migration
  def self.up
    execute "INSERT INTO merge_request_diffs ( merge_request_id ) SELECT id FROM merge_requests"
    execute "UPDATE merge_requests mr, merge_request_diffs md SET md.st_commits = mr.st_commits WHERE md.merge_request_id = mr.id"
    execute "UPDATE merge_requests mr, merge_request_diffs md SET md.st_diffs = mr.st_diffs WHERE md.merge_request_id = mr.id"
  end

  def self.down
    MergeRequestDiff.delete_all
  end
end
