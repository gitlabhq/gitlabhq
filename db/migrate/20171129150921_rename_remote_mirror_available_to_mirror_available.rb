class RenameRemoteMirrorAvailableToMirrorAvailable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :application_settings, :remote_mirror_available, :mirror_available
  end

  def down
    cleanup_concurrent_column_rename :application_settings, :mirror_available, :remote_mirror_available
  end
end
