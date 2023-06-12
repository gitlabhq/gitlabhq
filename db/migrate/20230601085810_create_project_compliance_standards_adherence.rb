# frozen_string_literal: true

class CreateProjectComplianceStandardsAdherence < Gitlab::Database::Migration[2.1]
  def change
    create_table :project_compliance_standards_adherence do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :namespace_id, null: false
      t.integer :status, null: false, limit: 2
      t.integer :check_name, null: false, limit: 2
      t.integer :standard, null: false, limit: 2

      t.index :namespace_id
      t.index :project_id
      t.index [:project_id, :check_name, :standard], unique: true,
        name: 'u_project_compliance_standards_adherence_for_reporting'
    end
  end
end
