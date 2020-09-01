# frozen_string_literal: true

class AddIndexOnMergeRequestIdAndRuleTypeToApprovalMergeRequestRule < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = "approval_mr_rule_index_merge_request_id"

  def up
    add_concurrent_index(
      :approval_merge_request_rules,
      :merge_request_id,
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end
