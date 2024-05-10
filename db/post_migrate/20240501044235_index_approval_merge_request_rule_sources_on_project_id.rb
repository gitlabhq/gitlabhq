# frozen_string_literal: true

class IndexApprovalMergeRequestRuleSourcesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_merge_request_rule_sources_on_project_id'

  def up
    add_concurrent_index :approval_merge_request_rule_sources, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rule_sources, INDEX_NAME
  end
end
