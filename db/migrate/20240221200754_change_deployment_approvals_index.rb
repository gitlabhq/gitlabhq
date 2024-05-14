# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ChangeDeploymentApprovalsIndex < Gitlab::Database::Migration[2.2]
  NEW_INDEX_NAME =
    'index_deployment_approvals_on_deployment_user_approval_rule'

  OLD_INDEX_NAME =
    'index_deployment_approvals_on_deployment_id_and_user_id'

  disable_ddl_transaction!

  milestone '16.10'

  def up
    add_concurrent_index :deployment_approvals,
      %i[deployment_id user_id approval_rule_id],
      name: NEW_INDEX_NAME,
      unique: true

    remove_concurrent_index :deployment_approvals,
      %i[deployment_id user_id],
      name: OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :deployment_approvals,
      %i[deployment_id user_id],
      name: OLD_INDEX_NAME,
      unique: true

    remove_concurrent_index :deployment_approvals,
      %i[deployment_id user_id approval_rule_id],
      name: NEW_INDEX_NAME
  end
end
