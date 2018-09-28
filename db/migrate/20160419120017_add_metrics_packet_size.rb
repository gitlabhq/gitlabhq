class AddMetricsPacketSize < ActiveRecord::Migration
  def change
    add_column :application_settings, :metrics_packet_size, :integer, default: 1
  end
end
