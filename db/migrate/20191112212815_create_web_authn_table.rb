# frozen_string_literal: true

class CreateWebAuthnTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # disable_ddl_transaction!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limits are added in subsequent migration
  def change
    create_table :webauthn_registrations do |t|
      t.bigint :user_id, null: false, index: true

      t.bigint :counter, default: 0, null: false
      t.timestamps_with_timezone
      t.text :credential_xid, null: false, index: { unique: true }
      t.text :name, null: false
      # The length of the public key is determined by the device
      # and not specified. Thus we can't set a limit
      t.text :public_key, null: false # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
