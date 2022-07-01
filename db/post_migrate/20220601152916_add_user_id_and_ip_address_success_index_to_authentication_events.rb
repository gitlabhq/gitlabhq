# frozen_string_literal: true

class AddUserIdAndIpAddressSuccessIndexToAuthenticationEvents < Gitlab::Database::Migration[2.0]
  OLD_INDEX_NAME = 'index_authentication_events_on_user_id'
  NEW_INDEX_NAME = 'index_authentication_events_on_user_and_ip_address_and_result'

  disable_ddl_transaction!

  def up
    add_concurrent_index :authentication_events, [:user_id, :ip_address, :result], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :authentication_events, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :authentication_events, :user_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :authentication_events, NEW_INDEX_NAME
  end
end
