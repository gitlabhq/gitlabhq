# frozen_string_literal: true

class RemoveFkAiInstanceAccessibleEntityRulesNamespace < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  FK_NAME = 'fk_rails_43a6361a35'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :ai_instance_accessible_entity_rules, :namespaces, name: FK_NAME
    end
  end

  def down
    add_concurrent_foreign_key :ai_instance_accessible_entity_rules, :namespaces,
      name: FK_NAME, column: :through_namespace_id, on_delete: :cascade
  end
end
