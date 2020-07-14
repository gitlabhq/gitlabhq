# frozen_string_literal: true

class ChangePrometheusMetricsIdentifierIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  NEW_INDEX = :index_prometheus_metrics_on_identifier_and_null_project
  OLD_INDEX = :index_prometheus_metrics_on_identifier

  disable_ddl_transaction!

  def up
    add_concurrent_index            :prometheus_metrics, :identifier, name: NEW_INDEX, unique: true, where: 'project_id IS NULL'
    remove_concurrent_index_by_name :prometheus_metrics, OLD_INDEX
  end

  def down
    add_concurrent_index            :prometheus_metrics, :identifier, name: OLD_INDEX, unique: true
    remove_concurrent_index_by_name :prometheus_metrics, NEW_INDEX
  end
end
