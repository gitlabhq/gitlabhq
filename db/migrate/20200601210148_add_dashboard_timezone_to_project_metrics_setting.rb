# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDashboardTimezoneToProjectMetricsSetting < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :project_metrics_settings, :dashboard_timezone, :integer, limit: 2, null: false, default: 0
  end
end
