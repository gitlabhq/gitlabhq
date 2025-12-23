# frozen_string_literal: true

class AddProjectIdToDeploymentClusters < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    add_column :deployment_clusters, :project_id, :bigint
  end
end
