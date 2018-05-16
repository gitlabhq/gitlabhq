class CleanupRemoteMirrorAvailableRename < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # When moving from CE to EE, the column may already have been renamed.
    return unless column_exists?(:application_settings, :remote_mirror_available)

    cleanup_concurrent_column_rename :application_settings, :remote_mirror_available, :mirror_available
  end

  def down
    return if column_exists?(:application_settings, :remote_mirror_available)

    rename_column_concurrently :application_settings, :mirror_available, :remote_mirror_available
  end
end
