# frozen_string_literal: true

class AddIndexesToResourceLabelEventsToSupportVsa < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_INDEX_NAME_ON_ISSUE_ID = 'index_resource_label_events_issue_id_label_id_action'
  OLD_INDEX_NAME_ON_ISSUE_ID = 'index_resource_label_events_on_issue_id'

  NEW_INDEX_NAME_ON_MERGE_REQUEST_ID = 'index_resource_label_events_on_merge_request_id_label_id_action'
  OLD_INDEX_NAME_ON_MERGE_REQUEST_ID = 'index_resource_label_events_on_merge_request_id'

  def up
    add_concurrent_index :resource_label_events, [:issue_id, :label_id, :action], name: NEW_INDEX_NAME_ON_ISSUE_ID
    remove_concurrent_index_by_name :resource_label_events, OLD_INDEX_NAME_ON_ISSUE_ID

    add_concurrent_index :resource_label_events, [:merge_request_id, :label_id, :action], name: NEW_INDEX_NAME_ON_MERGE_REQUEST_ID
    remove_concurrent_index_by_name :resource_label_events, OLD_INDEX_NAME_ON_MERGE_REQUEST_ID
  end

  def down
    add_concurrent_index :resource_label_events, :issue_id, name: OLD_INDEX_NAME_ON_ISSUE_ID
    remove_concurrent_index_by_name(:resource_label_events, NEW_INDEX_NAME_ON_ISSUE_ID)

    add_concurrent_index :resource_label_events, :merge_request_id, name: OLD_INDEX_NAME_ON_MERGE_REQUEST_ID
    remove_concurrent_index_by_name(:resource_label_events, NEW_INDEX_NAME_ON_MERGE_REQUEST_ID)
  end
end
