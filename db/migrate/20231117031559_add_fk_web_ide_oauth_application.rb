# frozen_string_literal: true

class AddFkWebIdeOauthApplication < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_application_settings_web_ide_oauth_application_id'

  def up
    add_concurrent_index :application_settings, :web_ide_oauth_application_id, name: INDEX_NAME
    add_concurrent_foreign_key :application_settings, :oauth_applications,
      column: :web_ide_oauth_application_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :application_settings, column: :web_ide_oauth_application_id
    end
    remove_concurrent_index_by_name :application_settings, INDEX_NAME
  end
end
