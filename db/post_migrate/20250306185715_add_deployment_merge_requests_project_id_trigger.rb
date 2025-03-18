# frozen_string_literal: true

class AddDeploymentMergeRequestsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :deployment_merge_requests,
      sharding_key: :project_id,
      parent_table: :deployments,
      parent_sharding_key: :project_id,
      foreign_key: :deployment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :deployment_merge_requests,
      sharding_key: :project_id,
      parent_table: :deployments,
      parent_sharding_key: :project_id,
      foreign_key: :deployment_id
    )
  end
end
