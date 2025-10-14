# frozen_string_literal: true

class AddNotNullConstraintToJiraConnectInstallationsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :jira_connect_installations, :organization_id, validate: false
  end

  def down
    remove_not_null_constraint :jira_connect_installations, :organization_id
  end
end
