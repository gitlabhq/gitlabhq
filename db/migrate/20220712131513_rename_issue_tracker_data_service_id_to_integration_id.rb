# frozen_string_literal: true

class RenameIssueTrackerDataServiceIdToIntegrationId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :issue_tracker_data, :service_id, :integration_id
  end

  def down
    undo_rename_column_concurrently :issue_tracker_data, :service_id, :integration_id
  end
end
