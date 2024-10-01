# frozen_string_literal: true

class AddPagesDeploymentStatesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :pages_deployment_states,
      sharding_key: :project_id,
      parent_table: :pages_deployments,
      parent_sharding_key: :project_id,
      foreign_key: :pages_deployment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :pages_deployment_states,
      sharding_key: :project_id,
      parent_table: :pages_deployments,
      parent_sharding_key: :project_id,
      foreign_key: :pages_deployment_id
    )
  end
end
