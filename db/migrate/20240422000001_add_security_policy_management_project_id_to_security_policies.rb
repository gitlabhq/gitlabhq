# frozen_string_literal: true

class AddSecurityPolicyManagementProjectIdToSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    return if column_exists?(:security_policies, :security_policy_management_project_id)

    # rubocop:disable Migration/AddReference -- table is empty
    # rubocop:disable Rails/NotNullColumn -- table is empty
    add_reference :security_policies,
      :security_policy_management_project,
      index: false,
      null: false,
      foreign_key: { on_delete: :cascade, to_table: :projects }
    # rubocop:enable Migration/AddReference
    # rubocop:enable Rails/NotNullColumn
  end

  def down
    return unless column_exists?(:security_policies, :security_policy_management_project_id)

    remove_reference :security_policies, :security_policy_management_project
  end
end
