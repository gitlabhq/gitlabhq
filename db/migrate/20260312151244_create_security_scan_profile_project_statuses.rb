# frozen_string_literal: true

class CreateSecurityScanProfileProjectStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  PROJECT_PROFILE_UNIQUE_INDEX = 'idx_security_scan_profile_proj_statuses_on_project_and_profile'
  PROFILE_INDEX = 'idx_security_scan_profile_proj_statuses_on_profile_id'
  BUILD_INDEX = 'idx_security_scan_profile_proj_statuses_on_build_id'

  def change
    create_table :security_scan_profile_project_statuses do |t|
      t.bigint :project_id, null: false
      t.references :security_scan_profile, foreign_key: { on_delete: :cascade },
        index: { name: PROFILE_INDEX }, null: false
      t.bigint :build_id
      t.datetime_with_timezone :last_scan_at
      t.timestamps_with_timezone null: false

      t.integer :status, limit: 2, null: false, default: 0
      t.integer :consecutive_failure_count, limit: 2, null: false, default: 0
      t.integer :consecutive_success_count, limit: 2, null: false, default: 0

      t.index [:project_id, :security_scan_profile_id], unique: true, name: PROJECT_PROFILE_UNIQUE_INDEX
      t.index :build_id, name: BUILD_INDEX
    end
  end
end
