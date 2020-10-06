# frozen_string_literal: true

class AddMergeRequestsFkToResourceIterationEventsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :resource_iteration_events, :merge_requests, column: :merge_request_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :resource_iteration_events, column: :merge_request_id
    end
  end
end
