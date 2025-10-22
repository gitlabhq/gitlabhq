# frozen_string_literal: true

class RemoveIssueTrackerDataInstanceIntegrationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    remove_column :issue_tracker_data, :instance_integration_id
  end

  def down
    add_column :issue_tracker_data, :instance_integration_id, :bigint
  end
end
