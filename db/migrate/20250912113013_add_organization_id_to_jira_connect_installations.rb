# frozen_string_literal: true

class AddOrganizationIdToJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :jira_connect_installations, :organization_id, :bigint
  end
end
