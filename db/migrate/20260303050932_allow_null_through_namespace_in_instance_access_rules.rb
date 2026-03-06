# frozen_string_literal: true

class AllowNullThroughNamespaceInInstanceAccessRules < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      change_column_null :ai_instance_accessible_entity_rules, :through_namespace_id, true
    end

    add_concurrent_index :ai_instance_accessible_entity_rules,
      :accessible_entity,
      unique: true,
      where: 'through_namespace_id IS NULL',
      name: 'idx_ai_iaer_default_rule_on_accessible_entity'
  end

  def down
    remove_concurrent_index_by_name :ai_instance_accessible_entity_rules,
      'idx_ai_iaer_default_rule_on_accessible_entity'

    with_lock_retries do
      change_column_null :ai_instance_accessible_entity_rules, :through_namespace_id, false
    end
  end
end
