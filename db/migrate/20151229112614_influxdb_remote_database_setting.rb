class InfluxdbRemoteDatabaseSetting < ActiveRecord::Migration
  def change
    remove_column :application_settings, :metrics_database
  end
end
