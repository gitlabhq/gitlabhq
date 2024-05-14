# frozen_string_literal: true

class AddIndexSecurityPolicyManagementProjectIdOnSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_security_policies_on_policy_management_project_id'

  def up
    add_concurrent_index :security_policies, :security_policy_management_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_policies, INDEX_NAME
  end
end
