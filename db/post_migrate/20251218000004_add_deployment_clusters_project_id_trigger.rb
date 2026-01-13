# frozen_string_literal: true

class AddDeploymentClustersProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    install_sharding_key_assignment_trigger(
      table: :deployment_clusters,
      sharding_key: :project_id,
      parent_table: :deployments,
      parent_sharding_key: :project_id,
      foreign_key: :deployment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :deployment_clusters,
      sharding_key: :project_id,
      parent_table: :deployments,
      parent_sharding_key: :project_id,
      foreign_key: :deployment_id
    )
  end
end
