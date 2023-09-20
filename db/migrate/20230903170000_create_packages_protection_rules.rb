# frozen_string_literal: true

class CreatePackagesProtectionRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :packages_protection_rules do |t|
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :push_protected_up_to_access_level, null: false
      t.integer :package_type, limit: 2, null: false
      t.text :package_name_pattern, limit: 255, null: false

      t.index [:project_id, :package_type, :package_name_pattern], unique: true,
        name: :i_packages_unique_project_id_package_type_package_name_pattern
    end
  end
end
