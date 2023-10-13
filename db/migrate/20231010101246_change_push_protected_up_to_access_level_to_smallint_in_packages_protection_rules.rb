# frozen_string_literal: true

class ChangePushProtectedUpToAccessLevelToSmallintInPackagesProtectionRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    change_column :packages_protection_rules, :push_protected_up_to_access_level, :integer, limit: 2
  end

  def down
    change_column :packages_protection_rules, :push_protected_up_to_access_level, :integer
  end
end
