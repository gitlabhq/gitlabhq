# frozen_string_literal: true

class ReplaceMrClosingIssuesMrLinkTypeIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :merge_requests_closing_issues
  OLD_INDEX = 'index_mr_closing_issues_on_merge_request_id_and_link_type'
  NEW_INDEX = 'idx_mr_closing_issues_on_mr_link_issue_from'

  # Widen the (merge_request_id, link_type) index to also cover the create-path
  # find_or_initialize lookup, which filters issue_id and from_mr_description on
  # top of merge_request_id + link_type. (merge_request_id, link_type) remains
  # the leftmost prefix, so the existing MR-side readers are unaffected.
  def up
    add_concurrent_index TABLE, [:merge_request_id, :link_type, :issue_id, :from_mr_description], name: NEW_INDEX
    remove_concurrent_index_by_name TABLE, OLD_INDEX
  end

  def down
    add_concurrent_index TABLE, [:merge_request_id, :link_type], name: OLD_INDEX
    remove_concurrent_index_by_name TABLE, NEW_INDEX
  end
end
