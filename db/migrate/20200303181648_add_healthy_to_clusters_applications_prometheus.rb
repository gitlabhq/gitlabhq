# frozen_string_literal: true

class AddHealthyToClustersApplicationsPrometheus < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # Default is null to indicate that a health check has not run for a project
    # For now, health checks will only run on monitor demo projects
    add_column :clusters_applications_prometheus, :healthy, :boolean
  end

  def down
    remove_column :clusters_applications_prometheus, :healthy
  end
end
