class AddStartCommitIdToMergeRequestDiffs < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_request_diffs, :start_commit_sha, :string
  end
end
