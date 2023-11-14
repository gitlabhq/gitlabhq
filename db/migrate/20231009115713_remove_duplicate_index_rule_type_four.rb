# frozen_string_literal: true

class RemoveDuplicateIndexRuleTypeFour < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'any_approver_merge_request_rule_type_unique_index'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_merge_request_rules, [:merge_request_id, :rule_type], where: 'rule_type = 4',
      name: INDEX_NAME, unique: true
  end
end
