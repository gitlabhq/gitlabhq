# frozen_string_literal: true

class AddShardingKeyToSlackIntegrationsScopes < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :slack_integrations_scopes, :project_id, :bigint
    add_column :slack_integrations_scopes, :group_id, :bigint
    add_column :slack_integrations_scopes, :organization_id, :bigint
  end
end
