# frozen_string_literal: true

class AddRootNamespaceFkToAiNamespaceFeatureAccessRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  def up
    add_concurrent_foreign_key :ai_namespace_feature_access_rules, :namespaces,
      column: :root_namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_namespace_feature_access_rules, column: :root_namespace_id,
        reverse_lock_order: true
    end
  end
end
