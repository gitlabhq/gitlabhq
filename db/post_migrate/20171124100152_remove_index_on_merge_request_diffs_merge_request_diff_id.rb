class RemoveIndexOnMergeRequestDiffsMergeRequestDiffId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if index_exists?(:merge_request_diffs, :merge_request_id)
      remove_concurrent_index(:merge_request_diffs, :merge_request_id)
    end
  end

  def down
    add_concurrent_index(:merge_request_diffs, :merge_request_id)
  end
end
