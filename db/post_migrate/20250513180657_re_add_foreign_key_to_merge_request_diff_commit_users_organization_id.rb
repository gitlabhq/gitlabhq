# frozen_string_literal: true

class ReAddForeignKeyToMergeRequestDiffCommitUsersOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_commit_users

  def up
    add_concurrent_foreign_key TABLE_NAME, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key TABLE_NAME, column: :organization_id
    end
  end
end
