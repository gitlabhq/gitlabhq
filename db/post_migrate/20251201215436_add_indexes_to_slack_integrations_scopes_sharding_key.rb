# frozen_string_literal: true

class AddIndexesToSlackIntegrationsScopesShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_index :slack_integrations_scopes,
      :project_id,
      name: 'index_slack_integrations_scopes_on_project_id'

    add_concurrent_index :slack_integrations_scopes,
      :group_id,
      name: 'index_slack_integrations_scopes_on_group_id'

    add_concurrent_index :slack_integrations_scopes,
      :organization_id,
      name: 'index_slack_integrations_scopes_on_organization_id'
  end

  def down
    remove_concurrent_index :slack_integrations_scopes,
      :project_id,
      name: 'index_slack_integrations_scopes_on_project_id'

    remove_concurrent_index :slack_integrations_scopes,
      :group_id,
      name: 'index_slack_integrations_scopes_on_group_id'

    remove_concurrent_index :slack_integrations_scopes,
      :organization_id,
      name: 'index_slack_integrations_scopes_on_organization_id'
  end
end
