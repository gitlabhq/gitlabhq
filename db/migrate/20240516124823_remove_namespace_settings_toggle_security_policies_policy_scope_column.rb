# frozen_string_literal: true

class RemoveNamespaceSettingsToggleSecurityPoliciesPolicyScopeColumn < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    remove_cascading_namespace_setting :toggle_security_policies_policy_scope
  end

  def down
    add_cascading_namespace_setting :toggle_security_policies_policy_scope, :boolean, default: false, null: false
  end
end
