# frozen_string_literal: true

class AddUsersFkToMobileDevicePushSubscriptions < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :mobile_device_push_subscriptions, :users,
      column: :user_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :mobile_device_push_subscriptions, column: :user_id
  end
end
