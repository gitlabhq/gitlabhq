# frozen_string_literal: true

class RenameSnowplowSiteIdToSnowplowAppId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :application_settings, :snowplow_site_id, :snowplow_app_id
  end

  def down
    undo_rename_column_concurrently :application_settings, :snowplow_site_id, :snowplow_app_id
  end
end
