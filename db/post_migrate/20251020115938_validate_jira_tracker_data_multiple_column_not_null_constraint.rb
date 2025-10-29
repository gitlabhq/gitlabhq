# frozen_string_literal: true

class ValidateJiraTrackerDataMultipleColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_eca1fbd6bd'

  def up
    validate_multi_column_not_null_constraint(
      :jira_tracker_data,
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
