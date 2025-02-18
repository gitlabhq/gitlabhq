# frozen_string_literal: true

class MakeAccessLevelsOnProtectionTagRulesNullable < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    change_column_null :container_registry_protection_tag_rules, :minimum_access_level_for_push, true
    change_column_null :container_registry_protection_tag_rules, :minimum_access_level_for_delete, true
  end
end
