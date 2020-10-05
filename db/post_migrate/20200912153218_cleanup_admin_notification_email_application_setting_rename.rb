# frozen_string_literal: true

class CleanupAdminNotificationEmailApplicationSettingRename < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :admin_notification_email, :abuse_notification_email
  end

  def down
    undo_cleanup_concurrent_column_rename :application_settings, :admin_notification_email, :abuse_notification_email
  end
end
