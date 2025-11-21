# frozen_string_literal: true

class AddOrganizationIdToScimOauthAccessTokens < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :scim_oauth_access_tokens, :organization_id, :bigint
  end
end
