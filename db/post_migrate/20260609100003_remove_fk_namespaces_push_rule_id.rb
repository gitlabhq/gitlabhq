# frozen_string_literal: true

class RemoveFkNamespacesPushRuleId < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  FOREIGN_KEY_NAME = 'fk_3448c97865'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :namespaces, :push_rules,
        column: :push_rule_id, name: FOREIGN_KEY_NAME
    end
  end

  def down
    add_concurrent_foreign_key :namespaces, :push_rules,
      column: :push_rule_id, on_delete: :nullify, name: FOREIGN_KEY_NAME
  end
end
