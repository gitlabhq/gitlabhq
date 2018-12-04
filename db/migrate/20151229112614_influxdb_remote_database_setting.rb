# rubocop:disable all
class InfluxdbRemoteDatabaseSetting < ActiveRecord::Migration[4.2]
  def change
    remove_column :application_settings, :metrics_database
  end
end
