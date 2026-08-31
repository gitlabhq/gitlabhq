# frozen_string_literal: true

class CreateDependencyManagementRemediations < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  UNIQUE_INDEX_NAME = 'idx_dm_remediations_on_project_purl_package_path_and_version'

  def up
    create_table :dependency_management_remediations do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      # Loose FK, nullified rather than deleted so a dismissal survives its
      # merge request being deleted.
      t.bigint :merge_request_id
      t.integer :purl_type, limit: 2, null: false
      t.integer :state, limit: 2, null: false

      t.text :package_name, limit: 255, null: false
      t.text :input_file_path, limit: 1024, null: false, default: ''
      # Part of the identity: some ecosystems (npm) allow the same package at
      # several versions in one manifest, each remediated separately.
      t.text :current_version, limit: 255, null: false
      t.text :target_version, limit: 255, null: false

      t.index [:project_id, :purl_type, :package_name, :input_file_path, :current_version],
        unique: true, name: UNIQUE_INDEX_NAME
      t.index :merge_request_id
    end
  end

  def down
    drop_table :dependency_management_remediations
  end
end
