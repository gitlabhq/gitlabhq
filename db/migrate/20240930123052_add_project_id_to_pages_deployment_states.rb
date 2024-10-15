# frozen_string_literal: true

class AddProjectIdToPagesDeploymentStates < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :pages_deployment_states, :project_id, :bigint
  end
end
