class AddBaseCommitShaToMergeRequestDiffs < ActiveRecord::Migration
  def change
    add_column :merge_request_diffs, :base_commit_sha, :string
  end
end
