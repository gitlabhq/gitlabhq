# frozen_string_literal: true

class AddIdentifierToPrometheusMetric < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :prometheus_metrics, :identifier, :string
    add_index :prometheus_metrics, :identifier, unique: true
  end
end
