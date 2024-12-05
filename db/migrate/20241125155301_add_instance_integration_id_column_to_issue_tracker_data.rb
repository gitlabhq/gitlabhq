# frozen_string_literal: true

class AddInstanceIntegrationIdColumnToIssueTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_tracker_data, :instance_integration_id, :bigint
  end
end
