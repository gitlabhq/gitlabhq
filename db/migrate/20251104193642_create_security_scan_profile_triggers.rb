# frozen_string_literal: true

class CreateSecurityScanProfileTriggers < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  PROFILE_TRIGGER_UNIQUE_INDEX = 'index_security_scan_profile_triggers_on_profile_trigger_unique'

  def change
    create_table :security_scan_profile_triggers do |t|
      t.timestamps_with_timezone null: false
      t.references :security_scan_profile, foreign_key: { on_delete: :cascade }, index: false, null: false
      t.bigint :namespace_id, index: true, null: false
      t.integer :trigger_type, null: false, limit: 2

      t.index [:security_scan_profile_id, :trigger_type], unique: true, name: PROFILE_TRIGGER_UNIQUE_INDEX
    end
  end
end
