# frozen_string_literal: true

class RemoveNamespacesPushRuleIdColumn < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    remove_column :namespaces, :push_rule_id, if_exists: true
  end

  def down
    add_column :namespaces, :push_rule_id, :bigint, if_not_exists: true
  end
end
