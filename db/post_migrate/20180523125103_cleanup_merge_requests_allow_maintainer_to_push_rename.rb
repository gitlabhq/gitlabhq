class CleanupMergeRequestsAllowMaintainerToPushRename < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :merge_requests, :allow_maintainer_to_push, :allow_collaboration
  end

  def down
    rename_column_concurrently :merge_requests, :allow_collaboration, :allow_maintainer_to_push
  end
end
