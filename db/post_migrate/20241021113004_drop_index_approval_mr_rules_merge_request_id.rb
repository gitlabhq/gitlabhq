# frozen_string_literal: true

class DropIndexApprovalMrRulesMergeRequestId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'approval_mr_rule_index_merge_request_id'

  disable_ddl_transaction!
  milestone '17.6'

  def up
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_merge_request_rules, :merge_request_id, name: INDEX_NAME
  end
end
