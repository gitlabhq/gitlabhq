# frozen_string_literal: true

class AddUserForeignKeyToDeploymentApprovals < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deployment_approvals, :users, column: :user_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :deployment_approvals, :users
    end
  end
end
