class RenameMergeRequestsAllowMaintainerToPush < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # NOOP
  end

  def down
    if column_exists?(:merge_requests, :allow_collaboration)
      cleanup_concurrent_column_rename :merge_requests, :allow_collaboration, :allow_maintainer_to_push
    end
  end
end
