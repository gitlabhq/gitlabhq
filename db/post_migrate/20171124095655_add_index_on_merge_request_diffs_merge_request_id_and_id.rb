class AddIndexOnMergeRequestDiffsMergeRequestIdAndId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:merge_request_diffs, [:merge_request_id, :id])
  end

  def down
    if index_exists?(:merge_request_diffs, [:merge_request_id, :id])
      remove_concurrent_index(:merge_request_diffs, [:merge_request_id, :id])
    end
  end
end
