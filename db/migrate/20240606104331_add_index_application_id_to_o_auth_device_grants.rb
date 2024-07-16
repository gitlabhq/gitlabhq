# frozen_string_literal: true

class AddIndexApplicationIdToOAuthDeviceGrants < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  INDEX_NAME = 'index_oauth_device_grants_on_application_id'

  def up
    add_concurrent_index :oauth_device_grants, :application_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :oauth_device_grants, INDEX_NAME
  end
end
