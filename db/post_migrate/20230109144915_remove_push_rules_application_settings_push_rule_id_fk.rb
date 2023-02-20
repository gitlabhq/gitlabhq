# frozen_string_literal: true

class RemovePushRulesApplicationSettingsPushRuleIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:application_settings, :push_rules, name: "fk_693b8795e4")

    with_lock_retries do
      execute('LOCK push_rules, application_settings IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:application_settings, :push_rules, name: "fk_693b8795e4")
    end
  end

  def down
    add_concurrent_foreign_key(:application_settings, :push_rules,
      name: "fk_693b8795e4", column: :push_rule_id,
      target_column: :id, on_delete: :nullify)
  end
end
