# frozen_string_literal: true

class AddDashboardPathToPrometheusMetrics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # Text limit is added in 20200730210506_add_text_limit_to_dashboard_path
    add_column :prometheus_metrics, :dashboard_path, :text # rubocop:disable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :prometheus_metrics, :dashboard_path
  end
end
