# frozen_string_literal: true

class RemoveOpenProjectDataTable < Gitlab::Database::Migration[1.0]
  def up
    drop_table :open_project_tracker_data
  end

  def down
    create_table :open_project_tracker_data do |t|
      t.integer :service_id, index: { name: 'index_open_project_tracker_data_on_service_id' }, null: false
      t.timestamps_with_timezone
      t.string :encrypted_url, limit: 255
      t.string :encrypted_url_iv, limit: 255
      t.string :encrypted_api_url, limit: 255
      t.string :encrypted_api_url_iv, limit: 255
      t.string :encrypted_token, limit: 255
      t.string :encrypted_token_iv, limit: 255
      t.string :closed_status_id, limit: 5
      t.string :project_identifier_code, limit: 100
    end
  end
end
