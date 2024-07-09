# frozen_string_literal: true

class CreateDoorkeeperDeviceGrants < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  def up
    create_table :oauth_device_grants do |t| # rubocop:disable Migration/EnsureFactoryForTable -- No factory needed
      t.bigint :resource_owner_id, null: true
      t.bigint :application_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :last_polling_at, null: true
      t.integer :expires_in, null: false
      t.text :scopes, null: false, default: '', limit: 255
      t.text :device_code, null: false, limit: 255
      t.text :user_code, null: true, limit: 255
    end
  end

  def down
    drop_table :oauth_device_grants
  end
end
