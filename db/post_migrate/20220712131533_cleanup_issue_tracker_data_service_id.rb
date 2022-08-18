# frozen_string_literal: true

class CleanupIssueTrackerDataServiceId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :issue_tracker_data, :service_id, :integration_id
  end

  def down
    undo_cleanup_concurrent_column_rename :issue_tracker_data, :service_id, :integration_id
  end
end
