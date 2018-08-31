# frozen_string_literal: true

class AddIdentifierToPrometheusMetric < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :prometheus_metrics, :identifier, :string, unique: true
  end
end
