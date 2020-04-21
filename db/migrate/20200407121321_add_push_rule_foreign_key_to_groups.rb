# frozen_string_literal: true

class AddPushRuleForeignKeyToGroups < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :push_rule_id, unique: true
    add_concurrent_foreign_key :namespaces, :push_rules, column: :push_rule_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :namespaces, column: :push_rule_id
    remove_concurrent_index :namespaces, :push_rule_id
  end
end
