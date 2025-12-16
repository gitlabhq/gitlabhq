# frozen_string_literal: true

class AddSlackApiScopesUniqueIndexOnOrganizationName < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_index :slack_api_scopes,
      [:organization_id, :name],
      unique: true,
      name: 'idx_unique_slack_api_scopes_on_organization_id_and_name'
  end

  def down
    remove_concurrent_index_by_name :slack_api_scopes, 'idx_unique_slack_api_scopes_on_organization_id_and_name'
  end
end
