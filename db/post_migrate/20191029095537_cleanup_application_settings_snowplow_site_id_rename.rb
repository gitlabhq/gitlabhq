# frozen_string_literal: true

class CleanupApplicationSettingsSnowplowSiteIdRename < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :snowplow_site_id, :snowplow_app_id
  end

  def down
    undo_cleanup_concurrent_column_rename :application_settings, :snowplow_site_id, :snowplow_app_id
  end
end
