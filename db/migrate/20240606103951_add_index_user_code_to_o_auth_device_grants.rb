# frozen_string_literal: true

class AddIndexUserCodeToOAuthDeviceGrants < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  INDEX_NAME = 'index_oauth_device_grants_on_user_code'

  def up
    add_concurrent_index :oauth_device_grants, :user_code, unique: true
  end

  def down
    remove_concurrent_index_by_name :oauth_device_grants, :user_code
  end
end
