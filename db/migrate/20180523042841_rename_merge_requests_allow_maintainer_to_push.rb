class RenameMergeRequestsAllowMaintainerToPush < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :merge_requests, :allow_maintainer_to_push, :allow_collaboration
  end

  def down
    cleanup_concurrent_column_rename :merge_requests, :allow_collaboration, :allow_maintainer_to_push
  end
end
