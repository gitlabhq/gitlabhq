# frozen_string_literal: true

class AddCSPNamespaceLockedUntilToSecurityPolicySettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  TABLE = :security_policy_settings
  COLUMN = :csp_namespace_locked_until

  def up
    add_column TABLE, COLUMN, :datetime_with_timezone
  end

  def down
    remove_column TABLE, COLUMN, if_exists: true
  end
end
