# frozen_string_literal: true

class CreateProjectControlComplianceStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  INDEX_PROJECT_ID = 'idx_project_control_statuses_on_project_id'
  INDEX_NAMESPACE_ID = 'idx_project_control_statuses_on_namespace_id'
  INDEX_COMPLIANCE_REQUIREMENT_ID = 'idx_project_control_statuses_on_requirement_id'
  UNIQUE_COMPLIANCE_REQUIREMENTS_CONTROL_ID_PROJECT_ID = 'uniq_compliance_statuses_control_project_id'

  def change
    create_table :project_control_compliance_statuses do |t|
      t.timestamps_with_timezone null: false

      t.references :compliance_requirements_control, null: false,
        index: false,
        foreign_key: { on_delete: :cascade }
      t.bigint :project_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :compliance_requirement_id, null: false

      t.integer :status, limit: 2, null: false

      t.index :project_id, name: INDEX_PROJECT_ID
      t.index :namespace_id, name: INDEX_NAMESPACE_ID
      t.index :compliance_requirement_id, name: INDEX_COMPLIANCE_REQUIREMENT_ID
      t.index [:compliance_requirements_control_id, :project_id],
        name: UNIQUE_COMPLIANCE_REQUIREMENTS_CONTROL_ID_PROJECT_ID, unique: true
    end
  end
end
