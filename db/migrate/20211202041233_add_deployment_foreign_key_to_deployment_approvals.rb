# frozen_string_literal: true

class AddDeploymentForeignKeyToDeploymentApprovals < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deployment_approvals, :deployments, column: :deployment_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :deployment_approvals, :deployments
    end
  end
end
