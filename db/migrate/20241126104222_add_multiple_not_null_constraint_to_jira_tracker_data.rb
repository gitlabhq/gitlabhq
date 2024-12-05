# frozen_string_literal: true

class AddMultipleNotNullConstraintToJiraTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:jira_tracker_data, :integration_id, :instance_integration_id)
  end

  def down
    remove_multi_column_not_null_constraint(:jira_tracker_data, :integration_id, :instance_integration_id)
  end
end
