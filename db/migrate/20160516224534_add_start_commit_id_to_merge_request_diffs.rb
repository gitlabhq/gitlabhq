class AddStartCommitIdToMergeRequestDiffs < ActiveRecord::Migration
  def change
    add_column :merge_request_diffs, :start_commit_sha, :string
  end
end
