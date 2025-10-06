# frozen_string_literal: true

class RemoveNotNullConstraintOnIssueTrackerData < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    remove_check_constraint :issue_tracker_data, 'check_f02a3f53bf'
  end

  def down
    # no-op
  end
end
