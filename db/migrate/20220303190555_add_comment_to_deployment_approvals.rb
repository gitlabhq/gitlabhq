# frozen_string_literal: true

class AddCommentToDeploymentApprovals < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220303191047_add_text_limit_to_deployment_approvals_comment
  def change
    add_column :deployment_approvals, :comment, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
