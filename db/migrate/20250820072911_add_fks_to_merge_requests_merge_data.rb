# frozen_string_literal: true

class AddFksToMergeRequestsMergeData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = :merge_requests_merge_data

  def up
    add_concurrent_partitioned_foreign_key TABLE_NAME, :merge_requests, column: :merge_request_id, on_delete: :cascade
    add_concurrent_partitioned_foreign_key TABLE_NAME, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_partitioned_foreign_key TABLE_NAME, :users, column: :merge_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key TABLE_NAME, column: :merge_request_id
      remove_foreign_key TABLE_NAME, column: :project_id
      remove_foreign_key TABLE_NAME, column: :merge_user_id
    end
  end
end
