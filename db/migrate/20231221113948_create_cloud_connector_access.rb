# frozen_string_literal: true

class CreateCloudConnectorAccess < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.8'

  def change
    create_table :cloud_connector_access do |t|
      t.timestamps_with_timezone null: false
      t.jsonb :data, null: false
    end
  end
end
