class CleanupRemoteMirrorAvailableRename < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :remote_mirror_available, :mirror_available
  end

  def down
    rename_column_concurrently :application_settings, :mirror_available, :remote_mirror_available
  end
end
