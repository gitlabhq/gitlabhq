# frozen_string_literal: true

class AddApprovalRuleFkToDeploymentApprovals < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_deployment_approvals_on_approval_rule_id'

  def up
    add_concurrent_index :deployment_approvals, :approval_rule_id, name: INDEX_NAME
    add_concurrent_foreign_key :deployment_approvals, :protected_environment_approval_rules, column: :approval_rule_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :deployment_approvals, column: :approval_rule_id
    end

    remove_concurrent_index_by_name :deployment_approvals, INDEX_NAME
  end
end
