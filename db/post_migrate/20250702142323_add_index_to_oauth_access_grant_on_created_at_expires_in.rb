# frozen_string_literal: true

class AddIndexToOauthAccessGrantOnCreatedAtExpiresIn < Gitlab::Database::Migration[2.3]
  INDEX_NAME = "index_oauth_access_grants_on_created_at_expires_in"

  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_concurrent_index :oauth_access_grants, [:created_at, :expires_in], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :oauth_access_grants, INDEX_NAME
  end
end
