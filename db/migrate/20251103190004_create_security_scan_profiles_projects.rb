# frozen_string_literal: true

class CreateSecurityScanProfilesProjects < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  PROJECT_PROFILE_UNIQUE_INDEX = 'index_security_scan_profiles_projects_on_unique_project_profile'
  PROFILE_INDEX = 'idx_security_scan_profiles_projects_on_security_scan_profile_id'

  def change
    create_table :security_scan_profiles_projects do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.references :security_scan_profile, foreign_key: { on_delete: :cascade },
        index: { name: PROFILE_INDEX }, null: false

      t.index [:project_id, :security_scan_profile_id], unique: true, name: PROJECT_PROFILE_UNIQUE_INDEX
    end
  end
end
