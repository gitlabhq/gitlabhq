class PrometheusMetricsLimitsToMysql < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    return unless Gitlab::Database.mysql?

    change_column :prometheus_metrics, :query, :text, limit: 4096, default: nil
  end

  def down
  end
end
