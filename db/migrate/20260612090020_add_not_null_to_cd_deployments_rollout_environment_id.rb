# frozen_string_literal: true

class AddNotNullToCdDeploymentsRolloutEnvironmentId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_not_null_constraint :cd_deployments, :rollout_environment_id
  end

  def down
    remove_not_null_constraint :cd_deployments, :rollout_environment_id
  end
end
