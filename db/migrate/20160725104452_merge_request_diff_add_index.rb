class MergeRequestDiffAddIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_concurrent_index :merge_request_diffs, :merge_request_id
  end

  def down
    if index_exists?(:merge_request_diffs, :merge_request_id)
      remove_index :merge_request_diffs, :merge_request_id
    end
  end
end
