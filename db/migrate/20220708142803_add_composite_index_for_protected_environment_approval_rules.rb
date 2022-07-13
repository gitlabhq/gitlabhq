# frozen_string_literal: true

class AddCompositeIndexForProtectedEnvironmentApprovalRules < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  # uses `pe_` instead of `protected_environment_` because index limit is 63 characters
  INDEX_NAME = 'index_pe_approval_rules_on_required_approvals_and_created_at'

  def up
    add_concurrent_index :protected_environment_approval_rules, %i[required_approvals created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :protected_environment_approval_rules, %i[required_approvals created_at], name: INDEX_NAME
  end
end
