# frozen_string_literal: true

class AddCreatedAtAndIdIndexToDeploymentApprovals < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_deployment_approvals_on_created_at_and_id'

  def up
    add_concurrent_index :deployment_approvals, %i[created_at id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :deployment_approvals, %i[created_at id], name: INDEX_NAME
  end
end
