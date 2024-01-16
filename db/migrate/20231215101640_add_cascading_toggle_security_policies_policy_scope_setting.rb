# frozen_string_literal: true

class AddCascadingToggleSecurityPoliciesPolicyScopeSetting < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  enable_lock_retries!

  def up
    add_cascading_namespace_setting :toggle_security_policies_policy_scope, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :toggle_security_policies_policy_scope
  end
end
