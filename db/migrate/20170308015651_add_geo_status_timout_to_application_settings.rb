class AddGeoStatusTimoutToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :geo_status_timeout, :integer, default: 10
  end
end
