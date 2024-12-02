# frozen_string_literal: true

class RevertOauthOrganizationDefault < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  TABLES = [:oauth_access_grants, :oauth_access_tokens, :oauth_openid_requests, :oauth_device_grants]

  def change
    TABLES.each do |table|
      change_column_default(table, :organization_id, from: nil, to: 1)
    end
  end
end
