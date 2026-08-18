# frozen_string_literal: true

class CreateSecurityScanProfileConfigurations < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  INDEX_NAME = 'idx_sspc_on_security_scan_profile_id'

  def change
    create_table :security_scan_profile_configurations do |t|
      t.timestamps_with_timezone null: false
      t.references :security_scan_profile,
        foreign_key: { on_delete: :cascade }, index: { name: INDEX_NAME }, null: false
      t.bigint :namespace_id, index: true, null: false
      t.integer :configuration_version, limit: 2, default: 1, null: false
      t.jsonb :configuration, default: {}, null: false
    end
  end
end
