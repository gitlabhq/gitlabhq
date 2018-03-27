class AddNewCircuitbreakerSettingsToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings,
               :circuitbreaker_access_retries,
               :integer,
               default: 3
    add_column :application_settings,
               :circuitbreaker_backoff_threshold,
               :integer,
               default: 80
  end
end
