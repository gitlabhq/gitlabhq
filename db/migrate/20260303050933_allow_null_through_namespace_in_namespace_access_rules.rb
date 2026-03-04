# frozen_string_literal: true

class AllowNullThroughNamespaceInNamespaceAccessRules < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      change_column_null :ai_namespace_feature_access_rules, :through_namespace_id, true
    end

    add_concurrent_index :ai_namespace_feature_access_rules,
      [:root_namespace_id, :accessible_entity],
      unique: true,
      where: 'through_namespace_id IS NULL',
      name: 'idx_ai_nfar_default_rule_on_root_ns_accessible_entity'
  end

  def down
    remove_concurrent_index_by_name :ai_namespace_feature_access_rules,
      'idx_ai_nfar_default_rule_on_root_ns_accessible_entity'

    with_lock_retries do
      change_column_null :ai_namespace_feature_access_rules, :through_namespace_id, false
    end
  end
end
