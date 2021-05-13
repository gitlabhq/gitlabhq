# frozen_string_literal: true

class AddMergeRequestForeignKeyToStatusCheckResponses < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :status_check_responses, :merge_requests, column: :merge_request_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :status_check_responses, column: :merge_request_id
    end
  end
end
