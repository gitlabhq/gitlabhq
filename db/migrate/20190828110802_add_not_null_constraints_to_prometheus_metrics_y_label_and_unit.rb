class AddNotNullConstraintsToPrometheusMetricsYLabelAndUnit < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    change_column_null(:prometheus_metrics, :y_label, false)
    change_column_null(:prometheus_metrics, :unit, false)
  end
end
