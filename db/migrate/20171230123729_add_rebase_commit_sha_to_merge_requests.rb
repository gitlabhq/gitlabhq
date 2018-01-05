class AddRebaseCommitShaToMergeRequests < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :merge_requests, :rebase_commit_sha, :string
  end
end
