# frozen_string_literal: true

class CreateCloudConnectorKeys < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :cloud_connector_keys do |t|
      t.timestamps_with_timezone null: false
      t.column :secret_key, :jsonb
    end
  end
end
