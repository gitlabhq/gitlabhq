# frozen_string_literal: true

class RemoveTestReportRequirementIssueConstraint < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TARGET_TABLE = :requirements_management_test_reports
  CONSTRAINT_NAME = 'requirements_test_reports_requirement_id_xor_issue_id'

  def up
    remove_check_constraint TARGET_TABLE, CONSTRAINT_NAME
  end

  def down
    add_check_constraint(TARGET_TABLE, 'num_nonnulls(requirement_id, issue_id) = 1', CONSTRAINT_NAME)
  end
end
