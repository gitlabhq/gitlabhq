# frozen_string_literal: true

class AddIndexToProjectComplianceViolations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  NAMESPACE_ID_INDEX_NAME = 'idx_project_compliance_violations_on_namespace_id'
  CONTROL_ID_INDEX_NAME = 'idx_project_compliance_violations_on_control_id'
  PROJECT_ID_INDEX_NAME = 'idx_project_compliance_violations_on_project_id'

  def up
    add_concurrent_index :project_compliance_violations, :namespace_id, name: NAMESPACE_ID_INDEX_NAME
    add_concurrent_index :project_compliance_violations, :project_id, name: PROJECT_ID_INDEX_NAME
    add_concurrent_index :project_compliance_violations, :compliance_requirements_control_id,
      name: CONTROL_ID_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_compliance_violations, NAMESPACE_ID_INDEX_NAME
    remove_concurrent_index_by_name :project_compliance_violations, PROJECT_ID_INDEX_NAME
    remove_concurrent_index_by_name :project_compliance_violations, CONTROL_ID_INDEX_NAME
  end
end
