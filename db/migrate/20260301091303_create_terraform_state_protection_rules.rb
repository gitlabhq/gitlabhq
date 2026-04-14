# frozen_string_literal: true

class CreateTerraformStateProtectionRules < Gitlab::Database::Migration[2.3]
  TERRAFORM_STATE_PROTECTION_RULES_INDEX_NAME = 'idx_terraform_state_protection_rules_on_project_id_state_name'

  milestone '18.11'

  def change
    create_table :terraform_state_protection_rules do |t|
      t.timestamps_with_timezone null: false

      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.integer :minimum_access_level_for_write, limit: 2, null: false
      t.integer :allowed_from, limit: 2, null: false, default: 0
      t.text :state_name, null: false, limit: 255

      t.index [:project_id, :state_name], unique: true,
        name: TERRAFORM_STATE_PROTECTION_RULES_INDEX_NAME
    end
  end
end
