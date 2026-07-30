# frozen_string_literal: true

class AddBackgroundAccessToAiToolRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  BACKGROUND_ACCESS_ENUM_CONSTRAINT = 'chk_ai_tool_rules_background_access_enum'
  HAS_PERMISSION_CONSTRAINT = 'chk_ai_tool_rules_has_permission'
  NEW_HAS_PERMISSION = 'web_access IS NOT NULL OR local_access IS NOT NULL OR background_access IS NOT NULL'
  OLD_HAS_PERMISSION = 'web_access IS NOT NULL OR local_access IS NOT NULL'

  def up
    with_lock_retries do
      add_column :ai_tool_rules, :background_access, :integer, limit: 2, null: true, if_not_exists: true
    end

    # background_access excludes `ask` (value 1): a background flow has no human to approve.
    add_check_constraint :ai_tool_rules,
      'background_access IS NULL OR background_access IN (0, 2)',
      BACKGROUND_ACCESS_ENUM_CONSTRAINT

    # Widen the presence constraint so a rule that sets only background_access is valid.
    remove_check_constraint :ai_tool_rules, HAS_PERMISSION_CONSTRAINT
    add_check_constraint :ai_tool_rules, NEW_HAS_PERMISSION, HAS_PERMISSION_CONSTRAINT
  end

  def down
    remove_check_constraint :ai_tool_rules, HAS_PERMISSION_CONSTRAINT
    remove_check_constraint :ai_tool_rules, BACKGROUND_ACCESS_ENUM_CONSTRAINT

    # Re-add the original presence constraint without validating existing rows.
    # A background-only rule (web_access and local_access both NULL) is valid under the
    # widened constraint but would fail a validated re-add, and DML cleanup is not
    # allowed in a structure migration. NOT VALID still enforces the rule on new writes.
    add_check_constraint :ai_tool_rules, OLD_HAS_PERMISSION, HAS_PERMISSION_CONSTRAINT, validate: false

    with_lock_retries do
      remove_column :ai_tool_rules, :background_access, if_exists: true
    end
  end
end
