# frozen_string_literal: true

class AddMetricsDashboardAccessLevelToProjectFeature < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_features, :metrics_dashboard_access_level, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :project_features, :metrics_dashboard_access_level, :integer
    end
  end
end
