class AddBasicSnowplowAttributesToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :snowplow_enabled, :boolean, default: false, null: false
    add_column :application_settings, :snowplow_collector_uri, :string
    add_column :application_settings, :snowplow_site_id, :string
    add_column :application_settings, :snowplow_cookie_domain, :string
  end
end
