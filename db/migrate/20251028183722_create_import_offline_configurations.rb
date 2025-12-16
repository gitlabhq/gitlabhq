# frozen_string_literal: true

class CreateImportOfflineConfigurations < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    create_table :import_offline_configurations do |t|
      t.bigint :offline_export_id, index: true, null: false
      t.bigint :organization_id, index: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :provider, null: false, limit: 2
      t.text :bucket, null: false, limit: 256
      t.text :export_prefix, null: false, limit: 255
      t.jsonb :object_storage_credentials, null: false
    end
  end
end
