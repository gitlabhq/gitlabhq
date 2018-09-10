# frozen_string_literal: true

class ChangeProjectIdForPrometheusMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :prometheus_metrics, :project_id, true
  end
end
