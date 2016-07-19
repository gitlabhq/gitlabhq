class AddHeadCommitIdToMergeRequestDiffs < ActiveRecord::Migration
  def change
    add_column :merge_request_diffs, :head_commit_sha, :string
  end
end
