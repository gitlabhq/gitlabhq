# frozen_string_literal: true

class AddDeploymentApprovalsProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :deployment_approvals, :project_id
  end

  def down
    remove_not_null_constraint :deployment_approvals, :project_id
  end
end
