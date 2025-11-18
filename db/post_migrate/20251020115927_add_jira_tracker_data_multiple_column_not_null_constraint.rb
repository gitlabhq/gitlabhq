# frozen_string_literal: true

class AddJiraTrackerDataMultipleColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(
      :jira_tracker_data,
      :project_id,
      :group_id,
      :organization_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :jira_tracker_data,
      :project_id,
      :group_id,
      :organization_id
    )
  end
end
