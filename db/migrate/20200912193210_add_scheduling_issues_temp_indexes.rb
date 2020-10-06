# frozen_string_literal: true

class AddSchedulingIssuesTempIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :issue_links, [:source_id], where: 'link_type = 1', name: 'tmp_idx_blocking_type_links'
    add_concurrent_index :issue_links, [:target_id], where: 'link_type = 2', name: 'tmp_idx_blocked_by_type_links'
    add_concurrent_index :issues, :id, where: '(state_id = 1 AND blocking_issues_count = 0)', name: 'tmp_idx_index_issues_with_outdate_blocking_count'
  end

  def down
    remove_concurrent_index_by_name(:issue_links, 'tmp_idx_blocking_type_links')
    remove_concurrent_index_by_name(:issue_links, 'tmp_idx_blocked_by_type_links')
    remove_concurrent_index_by_name(:issues, 'tmp_idx_index_issues_with_outdate_blocking_count')
  end
end
