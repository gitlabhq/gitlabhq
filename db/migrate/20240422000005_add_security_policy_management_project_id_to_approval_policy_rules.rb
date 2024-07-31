# frozen_string_literal: true

class AddSecurityPolicyManagementProjectIdToApprovalPolicyRules < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    return if column_exists?(:approval_policy_rules, :security_policy_management_project_id)

    # rubocop:disable Migration/AddReference -- table is empty
    # rubocop:disable Rails/NotNullColumn -- table is empty
    add_reference :approval_policy_rules,
      :security_policy_management_project,
      index: false,
      null: false,
      foreign_key: { on_delete: :cascade, to_table: :projects }
    # rubocop:enable Migration/AddReference
    # rubocop:enable Rails/NotNullColumn
  end

  def down
    return unless column_exists?(:approval_policy_rules, :security_policy_management_project_id)

    remove_reference :approval_policy_rules, :security_policy_management_project
  end
end
