# frozen_string_literal: true

class AddMergedCommitShaToMergeRequests < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :merge_requests, :merged_commit_sha, :bytea unless column_exists?(:merge_requests, :merged_commit_sha)
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_requests, :merged_commit_sha if column_exists?(:merge_requests, :merged_commit_sha)
    end
  end
end
