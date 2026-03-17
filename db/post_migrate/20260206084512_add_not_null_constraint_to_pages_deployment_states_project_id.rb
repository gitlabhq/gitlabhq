# frozen_string_literal: true

class AddNotNullConstraintToPagesDeploymentStatesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  def up
    add_not_null_constraint :pages_deployment_states, :project_id
  end

  def down
    remove_not_null_constraint :pages_deployment_states, :project_id
  end
end
