# frozen_string_literal: true

class AddSourceMergeRequestIdToResourceStateEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_resource_state_events_on_source_merge_request_id'

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:resource_state_events, :source_merge_request_id)
      add_column :resource_state_events, :source_merge_request_id, :bigint
    end

    unless index_exists?(:resource_state_events, :source_merge_request_id, name: INDEX_NAME)
      add_index :resource_state_events, :source_merge_request_id, name: INDEX_NAME # rubocop: disable Migration/AddIndex
    end

    unless foreign_key_exists?(:resource_state_events, :merge_requests, column: :source_merge_request_id)
      with_lock_retries do
        add_foreign_key :resource_state_events, :merge_requests, column: :source_merge_request_id, on_delete: :nullify
      end
    end
  end

  def down
    with_lock_retries do
      remove_column :resource_state_events, :source_merge_request_id
    end
  end
end
