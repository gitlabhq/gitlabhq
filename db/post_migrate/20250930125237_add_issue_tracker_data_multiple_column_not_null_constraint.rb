# frozen_string_literal: true

class AddIssueTrackerDataMultipleColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(
      :issue_tracker_data,
      :project_id,
      :group_id,
      :organization_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :issue_tracker_data,
      :project_id,
      :group_id,
      :organization_id
    )
  end
end
