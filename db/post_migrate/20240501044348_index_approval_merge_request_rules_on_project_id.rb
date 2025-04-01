# frozen_string_literal: true

class IndexApprovalMergeRequestRulesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_merge_request_rules_on_project_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- large tables
    add_concurrent_index :approval_merge_request_rules, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end
