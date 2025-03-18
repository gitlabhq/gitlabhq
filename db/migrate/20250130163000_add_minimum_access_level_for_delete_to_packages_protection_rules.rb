# frozen_string_literal: true

class AddMinimumAccessLevelForDeleteToPackagesProtectionRules < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :packages_protection_rules, :minimum_access_level_for_delete, :smallint, null: true, if_not_exists: true
  end
end
