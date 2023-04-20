# frozen_string_literal: true

class AddConcurrentFkToMergeRequestAssignmentEvents < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_assignment_events,
      :merge_requests,
      column: :merge_request_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :merge_request_assignment_events, column: :merge_request_id
  end
end
