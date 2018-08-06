class InfluxdbUdpPortSetting < ActiveRecord::Migration
  def change
    add_column :application_settings, :metrics_port, :integer, default: 8089
  end
end
