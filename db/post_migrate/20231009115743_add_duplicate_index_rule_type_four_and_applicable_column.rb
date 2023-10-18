# frozen_string_literal: true

class AddDuplicateIndexRuleTypeFourAndApplicableColumn < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'unique_any_approver_merge_request_rule_type_post_merge'

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_merge_request_rules, [:merge_request_id, :rule_type, :applicable_post_merge],
      where: 'rule_type = 4', name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end
