class EnablePrometheusMetricsByDefault < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    change_column_default :application_settings, :prometheus_metrics_enabled, true
  end

  def down
    change_column_default :application_settings, :prometheus_metrics_enabled, false
  end
end
