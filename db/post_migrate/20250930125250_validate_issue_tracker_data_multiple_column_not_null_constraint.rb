# frozen_string_literal: true

class ValidateIssueTrackerDataMultipleColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  CONSTRAINT_NAME = 'check_f02a3f53bf'

  def up
    validate_multi_column_not_null_constraint(
      :issue_tracker_data,
      :project_id,
      :group_id,
      :organization_id,
      constraint_name: CONSTRAINT_NAME
    )
  end

  def down
    # no-op
  end
end
