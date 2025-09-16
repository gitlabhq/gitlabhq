# frozen_string_literal: true

class AddFkWorkspacesOauthApplication < Gitlab::Database::Migration[2.3]
  milestone "18.3"
  disable_ddl_transaction!

  INDEX_NAME = 'index_application_settings_workspaces_oauth_application_id'

  # @return [void]
  def up
    add_concurrent_index :application_settings, :workspaces_oauth_application_id, name: INDEX_NAME
    add_concurrent_foreign_key :application_settings, :oauth_applications,
      column: :workspaces_oauth_application_id,
      on_delete: :nullify
  end

  # @return [void]
  def down
    with_lock_retries do
      remove_foreign_key :application_settings, column: :workspaces_oauth_application_id
    end
    remove_concurrent_index_by_name :application_settings, INDEX_NAME
  end
end
