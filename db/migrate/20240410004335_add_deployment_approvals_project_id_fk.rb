# frozen_string_literal: true

class AddDeploymentApprovalsProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '16.11'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deployment_approvals, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :deployment_approvals, column: :project_id
    end
  end
end
