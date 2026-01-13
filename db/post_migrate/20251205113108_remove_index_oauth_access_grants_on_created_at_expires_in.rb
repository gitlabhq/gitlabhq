# frozen_string_literal: true

class RemoveIndexOauthAccessGrantsOnCreatedAtExpiresIn < Gitlab::Database::Migration[2.3]
  INDEX_NAME = "index_oauth_access_grants_on_created_at_expires_in"

  milestone '18.7'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :oauth_access_grants, INDEX_NAME
  end

  def down
    add_concurrent_index :oauth_access_grants, [:created_at, :expires_in], name: INDEX_NAME
  end
end
