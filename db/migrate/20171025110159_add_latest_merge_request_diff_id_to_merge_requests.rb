class AddLatestMergeRequestDiffIdToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :merge_requests, :latest_merge_request_diff_id, :integer
    add_concurrent_index :merge_requests, :latest_merge_request_diff_id

    add_concurrent_foreign_key :merge_requests, :merge_request_diffs,
                               column: :latest_merge_request_diff_id,
                               on_delete: :nullify
  end

  def down
    remove_foreign_key :merge_requests, column: :latest_merge_request_diff_id

    if index_exists?(:merge_requests, :latest_merge_request_diff_id)
      remove_concurrent_index :merge_requests, :latest_merge_request_diff_id
    end

    remove_column :merge_requests, :latest_merge_request_diff_id
  end
end
