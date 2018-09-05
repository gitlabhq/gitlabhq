# frozen_string_literal: true

class AddIndexForIdentifierToPrometheusMetric < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :prometheus_metrics, :identifier, unique: true
  end

  def down
    remove_concurrent_index :prometheus_metrics, :identifier, unique: true
  end
end
