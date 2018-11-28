class AddMetricsPacketSize < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :metrics_packet_size, :integer, default: 1
  end
end
