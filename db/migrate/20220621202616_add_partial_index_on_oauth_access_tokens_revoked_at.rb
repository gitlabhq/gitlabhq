# frozen_string_literal: true

class AddPartialIndexOnOauthAccessTokensRevokedAt < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'partial_index_resource_owner_id_created_at_token_not_revoked'
  EXISTING_INDEX_NAME = 'index_oauth_access_tokens_on_resource_owner_id'

  def up
    add_concurrent_index :oauth_access_tokens, [:resource_owner_id, :created_at],
                         name: INDEX_NAME, where: 'revoked_at IS NULL'
    remove_concurrent_index :oauth_access_tokens, :resource_owner_id, name: EXISTING_INDEX_NAME
  end

  def down
    add_concurrent_index :oauth_access_tokens, :resource_owner_id, name: EXISTING_INDEX_NAME
    remove_concurrent_index :oauth_access_tokens, [:resource_owner_id, :created_at], name: INDEX_NAME
  end
end
