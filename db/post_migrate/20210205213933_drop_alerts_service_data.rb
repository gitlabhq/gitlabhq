# frozen_string_literal: true

class DropAlertsServiceData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      drop_table :alerts_service_data
    end
  end

  # rubocop:disable Migration/PreventStrings
  def down
    with_lock_retries do
      create_table :alerts_service_data do |t|
        t.bigint :service_id, null: false
        t.timestamps_with_timezone
        t.string :encrypted_token, limit: 255
        t.string :encrypted_token_iv, limit: 255
      end
    end
  end
  # rubocop:enable Migration/PreventStrings
end
