# frozen_string_literal: true

class AddOrganizationIdToSlackApiScopes < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :slack_api_scopes, :organization_id, :bigint
  end
end
