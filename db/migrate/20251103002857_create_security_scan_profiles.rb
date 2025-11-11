# frozen_string_literal: true

class CreateSecurityScanProfiles < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  SECURITY_SCAN_PROFILES_NAMESPACE_TYPE_NAME_INDEX = 'index_security_scan_profiles_namespace_scan_type_name'

  def change
    create_table :security_scan_profiles do |t|
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :scan_type, null: false, limit: 2
      t.boolean :gitlab_recommended, null: false, default: false
      t.text :name, null: false, limit: 255
      t.text :description, default: nil, limit: 2047

      t.index 'namespace_id, scan_type, LOWER(name)', unique: true,
        name: SECURITY_SCAN_PROFILES_NAMESPACE_TYPE_NAME_INDEX
    end
  end
end
