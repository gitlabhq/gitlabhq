class CleanupApplicationSettingsSigninEnabledRename < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :signin_enabled, :password_authentication_enabled
  end

  def down
    rename_column_concurrently :application_settings, :password_authentication_enabled, :signin_enabled
  end
end
