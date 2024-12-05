# frozen_string_literal: true

class AddIndexOnInstanceIntegrationIdToIssueTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_tracker_data_on_instance_integration_id'

  def up
    add_concurrent_index :issue_tracker_data, :instance_integration_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_tracker_data, INDEX_NAME
  end
end
