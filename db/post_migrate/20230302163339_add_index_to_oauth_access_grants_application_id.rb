# frozen_string_literal: true

class AddIndexToOauthAccessGrantsApplicationId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_oauth_access_grants_on_application_id'

  def up
    add_concurrent_index :oauth_access_grants, :application_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :oauth_access_grants, name: INDEX_NAME
  end
end
