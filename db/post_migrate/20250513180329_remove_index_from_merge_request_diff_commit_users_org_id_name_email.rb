# frozen_string_literal: true

class RemoveIndexFromMergeRequestDiffCommitUsersOrgIdNameEmail < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_commit_users
  INDEX_NAME = 'index_merge_request_diff_commit_users_on_org_id_name_email'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, %w[organization_id name email], unique: true, name: INDEX_NAME
  end
end
