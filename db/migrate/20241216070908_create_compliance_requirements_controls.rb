# frozen_string_literal: true

class CreateComplianceRequirementsControls < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  INDEX_NAMESPACE_ID = 'idx_compliance_requirements_controls_on_namespace_id'
  UNIQUE_INDEX_NAME_REQUIREMENT_ID = 'uniq_compliance_requirements_controls_name_requirement_id'

  def change
    create_table :compliance_requirements_controls do |t|
      t.timestamps_with_timezone null: false

      t.references :compliance_requirement, null: false,
        index: false,
        foreign_key: { on_delete: :cascade }
      t.bigint :namespace_id, null: false
      t.integer :name, limit: 2, null: false
      t.integer :control_type, limit: 2, null: false
      t.text :expression, limit: 255

      t.index :namespace_id, name: INDEX_NAMESPACE_ID
      t.index [:compliance_requirement_id, :name], name: UNIQUE_INDEX_NAME_REQUIREMENT_ID, unique: true
    end
  end
end
