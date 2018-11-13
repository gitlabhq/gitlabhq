class AddMetricsSampleInterval < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :metrics_sample_interval, :integer,
      default: 15
  end
end
