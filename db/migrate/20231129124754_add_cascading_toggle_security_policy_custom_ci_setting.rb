# frozen_string_literal: true

class AddCascadingToggleSecurityPolicyCustomCiSetting < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  enable_lock_retries!

  def up
    add_cascading_namespace_setting :toggle_security_policy_custom_ci, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :toggle_security_policy_custom_ci
  end
end
