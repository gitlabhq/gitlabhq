# frozen_string_literal: true

class IndexErrorTrackingErrorEventsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_error_tracking_error_events_on_project_id'

  def up
    add_concurrent_index :error_tracking_error_events, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :error_tracking_error_events, INDEX_NAME
  end
end
