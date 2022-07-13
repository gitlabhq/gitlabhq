# frozen_string_literal: true

class ValidateRequirementsIssueIdNotNull < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    constraint_name = 'check_requirement_issue_not_null'

    validate_not_null_constraint(:requirements, :issue_id, constraint_name: constraint_name)
  end

  def down
    # No op
  end
end
