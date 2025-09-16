# frozen_string_literal: true

class DropRedundantUniqueIndexOnMergeRequestDiffCommitUsers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  def up
    remove_concurrent_index :merge_request_diff_commit_users, [:name, :email],
      name: 'index_merge_request_diff_commit_users_on_name_and_email'
  end

  def down
    add_concurrent_index :merge_request_diff_commit_users, [:name, :email],
      name: 'index_merge_request_diff_commit_users_on_name_and_email', unique: true
  end
end
