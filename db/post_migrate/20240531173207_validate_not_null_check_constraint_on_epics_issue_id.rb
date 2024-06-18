# frozen_string_literal: true

class ValidateNotNullCheckConstraintOnEpicsIssueId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  CONSTRAINT_NAME = 'check_450724d1bb'

  def up
    validate_not_null_constraint :epics, :issue_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
