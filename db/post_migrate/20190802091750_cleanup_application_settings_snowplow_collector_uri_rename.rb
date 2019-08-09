# frozen_string_literal: true

class CleanupApplicationSettingsSnowplowCollectorUriRename < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :snowplow_collector_uri, :snowplow_collector_hostname
  end

  def down
    rename_column_concurrently :application_settings, :snowplow_collector_hostname, :snowplow_collector_uri
  end
end
