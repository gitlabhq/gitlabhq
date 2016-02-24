class AddMergeCommitShaToMergeRequests < ActiveRecord::Migration
  def change
    add_column :merge_requests, :merge_commit_sha, :string
  end
end
