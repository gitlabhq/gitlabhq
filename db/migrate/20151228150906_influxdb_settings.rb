class InfluxdbSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :metrics_enabled, :boolean, default: false

    add_column :application_settings, :metrics_host, :string,
      default: 'localhost'

    add_column :application_settings, :metrics_database, :string,
      default: 'gitlab'

    add_column :application_settings, :metrics_username, :string
    add_column :application_settings, :metrics_password, :string
    add_column :application_settings, :metrics_pool_size, :integer, default: 16
    add_column :application_settings, :metrics_timeout, :integer, default: 10
    add_column :application_settings, :metrics_method_call_threshold,
      :integer, default: 10
  end
end
