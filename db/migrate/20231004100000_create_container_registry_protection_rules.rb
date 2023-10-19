# frozen_string_literal: true

class CreateContainerRegistryProtectionRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :container_registry_protection_rules do |t|
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :delete_protected_up_to_access_level, null: false, limit: 2
      t.integer :push_protected_up_to_access_level, null: false, limit: 2
      t.text :container_path_pattern, limit: 255, null: false

      t.index [:project_id, :container_path_pattern], unique: true,
        name: :i_container_protection_unique_project_id_container_path_pattern
    end
  end
end
