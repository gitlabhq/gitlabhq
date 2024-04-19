# frozen_string_literal: true

class AddSecurityPolicyManagementProjectIdToSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    # rubocop:disable Rails/NotNullColumn -- table is empty
    add_column :security_policies, :security_policy_management_project_id, :bigint, null: false
    # rubocop:enable Rails/NotNullColumn
  end

  def down
    remove_column :security_policies, :security_policy_management_project_id
  end
end
