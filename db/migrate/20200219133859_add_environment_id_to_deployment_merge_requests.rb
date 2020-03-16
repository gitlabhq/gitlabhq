# frozen_string_literal: true

class AddEnvironmentIdToDeploymentMergeRequests < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :deployment_merge_requests, :environment_id, :integer, null: true
  end
end
