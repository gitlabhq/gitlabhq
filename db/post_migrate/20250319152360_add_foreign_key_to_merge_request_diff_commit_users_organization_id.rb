# frozen_string_literal: true

class AddForeignKeyToMergeRequestDiffCommitUsersOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_diff_commit_users, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_diff_commit_users, column: :organization_id
    end
  end
end
