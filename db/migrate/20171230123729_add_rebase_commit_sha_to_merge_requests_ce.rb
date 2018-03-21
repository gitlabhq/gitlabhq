class AddRebaseCommitShaToMergeRequestsCe < ActiveRecord::Migration
  DOWNTIME = false

  def up
    unless column_exists?(:merge_requests, :rebase_commit_sha)
      add_column :merge_requests, :rebase_commit_sha, :string
    end
  end

  def down
    if column_exists?(:merge_requests, :rebase_commit_sha)
      remove_column :merge_requests, :rebase_commit_sha
    end
  end
end
