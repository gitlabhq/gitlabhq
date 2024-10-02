# frozen_string_literal: true

class RemoveToggleSecurityPolicyCustomCi < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    remove_cascading_namespace_setting :toggle_security_policy_custom_ci
  end

  def down
    add_cascading_namespace_setting :toggle_security_policy_custom_ci, :boolean, default: false, null: false
  end
end
