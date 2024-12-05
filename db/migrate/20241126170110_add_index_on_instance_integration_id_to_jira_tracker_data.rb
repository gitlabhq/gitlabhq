# frozen_string_literal: true

class AddIndexOnInstanceIntegrationIdToJiraTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  INDEX_NAME = 'index_jira_tracker_data_on_instance_integration_id'

  def up
    add_concurrent_index :jira_tracker_data, :instance_integration_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :jira_tracker_data, INDEX_NAME
  end
end
