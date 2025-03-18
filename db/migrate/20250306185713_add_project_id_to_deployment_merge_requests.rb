# frozen_string_literal: true

class AddProjectIdToDeploymentMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :deployment_merge_requests, :project_id, :bigint
  end
end
