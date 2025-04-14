# frozen_string_literal: true

class AddIndexToDeploymentApprovalsCiBuildId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  TABLE_NAME = :deployment_approvals
  INDEX_NAME = 'index_deployment_approvals_on_ci_build_id'

  def up
    add_concurrent_index TABLE_NAME, :ci_build_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
