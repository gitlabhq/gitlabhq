# frozen_string_literal: true

class AddIndexToProjectComplianceViolationsIssues < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  COMPOSITE_INDEX_NAME = 'idx_proj_comp_viol_issues_on_viol_id_issue_id'
  ISSUE_ID_INDEX_NAME = 'index_project_compliance_violations_issues_on_issue_id'
  PROJECT_ID_INDEX_NAME = 'index_project_compliance_violations_issues_on_project_id'

  def up
    add_concurrent_index :project_compliance_violations_issues, [:project_compliance_violation_id, :issue_id],
      name: COMPOSITE_INDEX_NAME, unique: true
    add_concurrent_index(:project_compliance_violations_issues, :project_id, name: PROJECT_ID_INDEX_NAME)
    add_concurrent_index(:project_compliance_violations_issues, :issue_id, name: ISSUE_ID_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name :project_compliance_violations_issues, COMPOSITE_INDEX_NAME
    remove_concurrent_index_by_name :project_compliance_violations_issues, PROJECT_ID_INDEX_NAME
    remove_concurrent_index_by_name :project_compliance_violations_issues, ISSUE_ID_INDEX_NAME
  end
end
