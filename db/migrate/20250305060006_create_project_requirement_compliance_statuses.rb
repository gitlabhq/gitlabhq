# frozen_string_literal: true

class CreateProjectRequirementComplianceStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  INDEX_PROJECT_ID = 'idx_project_requirement_statuses_on_project_id'
  INDEX_NAMESPACE_ID = 'idx_project_requirement_statuses_on_namespace_id'
  INDEX_FRAMEWORK_ID = 'idx_project_requirement_statuses_on_framework_id'
  UNIQUE_COMPLIANCE_REQUIREMENT_ID_PROJECT_ID = 'uniq_compliance_statuses_requirement_project_id'

  def change
    create_table :project_requirement_compliance_statuses do |t|
      t.timestamps_with_timezone null: false

      t.references :project, null: false,
        index: true,
        foreign_key: { on_delete: :restrict }

      t.bigint :namespace_id, null: false
      t.bigint :compliance_requirement_id, null: false
      t.bigint :compliance_framework_id, null: false

      t.integer :pass_count, null: false, default: 0
      t.integer :fail_count, null: false, default: 0
      t.integer :pending_count, null: false, default: 0

      t.index :namespace_id, name: INDEX_NAMESPACE_ID
      t.index :compliance_framework_id, name: INDEX_FRAMEWORK_ID

      t.index [:compliance_requirement_id, :project_id],
        name: UNIQUE_COMPLIANCE_REQUIREMENT_ID_PROJECT_ID, unique: true
    end
  end
end
