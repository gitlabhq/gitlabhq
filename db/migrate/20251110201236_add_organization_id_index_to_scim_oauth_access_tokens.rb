# frozen_string_literal: true

class AddOrganizationIdIndexToScimOauthAccessTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  INDEX_NAME = 'index_scim_oauth_access_tokens_on_organization_id'

  def up
    add_concurrent_index :scim_oauth_access_tokens, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :scim_oauth_access_tokens, INDEX_NAME
  end
end
