# frozen_string_literal: true

class RemoveIndexNamespacesOnPushRuleId < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_namespaces_on_push_rule_id'

  def up
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end

  def down
    add_concurrent_index :namespaces, :push_rule_id, unique: true, name: INDEX_NAME
  end
end
