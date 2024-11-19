# frozen_string_literal: true

class AddOrganizationIdIndexToOauthTables < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.6'

  TABLES = [:oauth_access_grants, :oauth_access_tokens, :oauth_openid_requests]

  def up
    TABLES.each do |table|
      add_concurrent_index table, :organization_id, name: "idx_#{table}_on_organization_id"
      add_concurrent_foreign_key table, :organizations, column: :organization_id, on_delete: :cascade
    end
  end

  def down
    TABLES.each do |table|
      remove_concurrent_index table, :organization_id, name: "idx_#{table}_on_organization_id"
      remove_foreign_key table, :organizations, column: :organization_id, on_delete: :cascade
    end
  end
end
