# frozen_string_literal: true

class CreateMobileDevicePushSubscriptions < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    create_table :mobile_device_push_subscriptions do |t|
      t.bigint :user_id, null: false, index: true
      t.datetime_with_timezone :last_seen_at, null: false, default: -> { 'NOW()' }, index: true
      t.timestamps_with_timezone null: false
      t.integer :platform, limit: 2, null: false, default: 0
      t.integer :apns_environment, limit: 2, null: false, default: 0
      t.integer :payload_mode, limit: 2, null: false, default: 0
      t.jsonb :device_token, null: false
      t.text :bundle_identifier, limit: 255
      t.text :device_name, limit: 255
      t.text :app_version, limit: 64
      t.text :locale, limit: 32

      t.index [:device_token, :apns_environment], unique: true,
        name: 'idx_mobile_push_subscriptions_on_token_and_environment'
    end
  end

  def down
    drop_table :mobile_device_push_subscriptions
  end
end
