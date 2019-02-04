# frozen_string_literal: true

class ChangeProjectIdForPrometheusMetrics < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :prometheus_metrics, :project_id, true
  end
end
