# frozen_string_literal: true

class CreateAlertsServiceData < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :alerts_service_data do |t|
      t.references :service, type: :integer, index: true, null: false,
        foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone
      t.string :encrypted_token, limit: 255
      t.string :encrypted_token_iv, limit: 255
    end
  end
  # rubocop:enable Migration/PreventStrings
end
