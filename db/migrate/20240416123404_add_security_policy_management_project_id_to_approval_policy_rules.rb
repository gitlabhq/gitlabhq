# frozen_string_literal: true

class AddSecurityPolicyManagementProjectIdToApprovalPolicyRules < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    # rubocop:disable Rails/NotNullColumn -- table is empty
    add_column :approval_policy_rules, :security_policy_management_project_id, :bigint, null: false
    # rubocop:enable Rails/NotNullColumn
  end

  def down
    remove_column :approval_policy_rules, :security_policy_management_project_id
  end
end
