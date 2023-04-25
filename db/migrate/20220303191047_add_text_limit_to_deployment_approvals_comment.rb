# frozen_string_literal: true

class AddTextLimitToDeploymentApprovalsComment < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :deployment_approvals, :comment, 255
  end

  def down
    remove_text_limit :deployment_approvals, :comment
  end
end
