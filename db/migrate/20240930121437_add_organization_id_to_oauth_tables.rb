# frozen_string_literal: true

class AddOrganizationIdToOauthTables < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  disable_ddl_transaction!
  milestone '17.6'

  TABLES = [:oauth_access_grants, :oauth_access_tokens, :oauth_openid_requests]

  def up
    TABLES.each do |table|
      with_lock_retries do
        add_column table, :organization_id, :bigint,
          default: DEFAULT_ORGANIZATION_ID,
          null: false,
          if_not_exists: true
      end
    end
  end

  def down
    TABLES.each do |table|
      remove_column table, :organization_id, :bigint
    end
  end
end
