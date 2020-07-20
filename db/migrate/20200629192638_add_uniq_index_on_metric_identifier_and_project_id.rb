# frozen_string_literal: true

class AddUniqIndexOnMetricIdentifierAndProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :prometheus_metrics, [:identifier, :project_id], unique: true
  end

  def down
    remove_concurrent_index :prometheus_metrics, [:identifier, :project_id]
  end
end
