class AddMergeCommitShaToMergeRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :merge_commit_sha, :string
  end
end
