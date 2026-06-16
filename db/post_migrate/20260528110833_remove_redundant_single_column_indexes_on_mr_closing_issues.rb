# frozen_string_literal: true

class RemoveRedundantSingleColumnIndexesOnMrClosingIssues < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  MR_ID_INDEX = 'index_merge_requests_closing_issues_on_merge_request_id'
  ISSUE_ID_INDEX = 'index_merge_requests_closing_issues_on_issue_id'

  # Both single-column indexes are now redundant: the composite indexes added
  # in the previous migration have merge_request_id and issue_id as their
  # leading columns, so they serve every query (and foreign-key lookup) the
  # single-column indexes served.
  def up
    remove_concurrent_index_by_name :merge_requests_closing_issues, name: MR_ID_INDEX
    remove_concurrent_index_by_name :merge_requests_closing_issues, name: ISSUE_ID_INDEX
  end

  def down
    add_concurrent_index :merge_requests_closing_issues, :merge_request_id, name: MR_ID_INDEX
    add_concurrent_index :merge_requests_closing_issues, :issue_id, name: ISSUE_ID_INDEX
  end
end
