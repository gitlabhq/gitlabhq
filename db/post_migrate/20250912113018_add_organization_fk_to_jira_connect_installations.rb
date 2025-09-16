# frozen_string_literal: true

class AddOrganizationFkToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :jira_connect_installations,
      :organizations,
      column: :organization_id,
      target_column: :id,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :jira_connect_installations, column: :organization_id
    end
  end
end
