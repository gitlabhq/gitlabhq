# frozen_string_literal: true

class AddDeploymentApprovalsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :deployment_approvals,
      sharding_key: :project_id,
      parent_table: :deployments,
      parent_sharding_key: :project_id,
      foreign_key: :deployment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :deployment_approvals,
      sharding_key: :project_id,
      parent_table: :deployments,
      parent_sharding_key: :project_id,
      foreign_key: :deployment_id
    )
  end
end
