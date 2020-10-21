# frozen_string_literal: true

class RenameAdminNotificationEmailApplicationSetting < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :application_settings, :admin_notification_email, :abuse_notification_email
  end

  def down
    undo_rename_column_concurrently :application_settings, :admin_notification_email, :abuse_notification_email
  end
end
