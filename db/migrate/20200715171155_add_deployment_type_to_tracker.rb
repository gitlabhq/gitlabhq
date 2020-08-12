# frozen_string_literal: true

class AddDeploymentTypeToTracker < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :jira_tracker_data, :deployment_type, :smallint, default: 0, null: false
  end
end
