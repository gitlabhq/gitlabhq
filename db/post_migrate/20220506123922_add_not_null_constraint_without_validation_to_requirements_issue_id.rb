# frozen_string_literal: true

class AddNotNullConstraintWithoutValidationToRequirementsIssueId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_requirement_issue_not_null'

  def up
    add_not_null_constraint(
      :requirements,
      :issue_id,
      constraint_name: CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_not_null_constraint :requirements, :issue_id, constraint_name: CONSTRAINT_NAME
  end
end
