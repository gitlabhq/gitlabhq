# frozen_string_literal: true

class AddPersonalAccessTokenIdToWorkspaces < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_workspaces_on_personal_access_token_id"

  def up
    with_lock_retries do
      add_column :workspaces, :personal_access_token_id, :bigint
    end

    add_concurrent_index :workspaces, :personal_access_token_id, name: INDEX_NAME

    # Personal Access Tokens are revokable and are soft deleted, so the record should never actually be deleted.
    # Therefore, `restrict` is the appropriate choice, because if a record ever is attempted to be deleted
    # outside of Rails, this should be prevented, because `nullify` would result in an invalid state for the workspace,
    # and `cascade` would delete the workspace.
    add_concurrent_foreign_key :workspaces,
      :personal_access_tokens,
      column: :personal_access_token_id,
      on_delete: :restrict
  end

  def down
    remove_concurrent_index_by_name :workspaces, INDEX_NAME
    remove_foreign_key_if_exists :workspaces, column: :personal_access_tokens

    with_lock_retries do
      remove_column :workspaces, :personal_access_token_id, if_exists: true
    end
  end
end
