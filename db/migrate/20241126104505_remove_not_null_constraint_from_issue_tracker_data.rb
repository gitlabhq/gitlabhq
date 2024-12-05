# frozen_string_literal: true

class RemoveNotNullConstraintFromIssueTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  def up
    remove_not_null_constraint :issue_tracker_data, :integration_id
  end

  def down
    add_not_null_constraint :issue_tracker_data, :integration_id
  end
end
