# frozen_string_literal: true

class CreateZentaoTrackerData < ActiveRecord::Migration[6.1]
  def change
    create_table :zentao_tracker_data do |t|
      t.references :integration, foreign_key: { on_delete: :cascade }, type: :bigint, index: true, null: false
      t.timestamps_with_timezone
      t.binary :encrypted_url
      t.binary :encrypted_url_iv
      t.binary :encrypted_api_url
      t.binary :encrypted_api_url_iv
      t.binary :encrypted_zentao_product_xid
      t.binary :encrypted_zentao_product_xid_iv
      t.binary :encrypted_api_token
      t.binary :encrypted_api_token_iv
    end
  end
end
