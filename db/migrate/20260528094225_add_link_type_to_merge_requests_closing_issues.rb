# frozen_string_literal: true

class AddLinkTypeToMergeRequestsClosingIssues < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  MR_LINK_TYPE_INDEX = 'index_mr_closing_issues_on_merge_request_id_and_link_type'
  ISSUE_LINK_TYPE_INDEX = 'index_mr_closing_issues_on_issue_id_and_link_type'
  UNIQUE_INDEX = 'index_mr_closing_issues_on_mr_id_issue_id_link_type'

  def up
    add_column :merge_requests_closing_issues, :link_type, :smallint, default: 0, null: false, if_not_exists: true

    # Two targeted, non-unique indexes serve the queries that read these rows:
    #   - (merge_request_id, link_type): the MR-side readers and FK lookups
    #     (e.g. cache_merge_request_closes_issues!, the cached_closes_issues
    #     through-association), replacing the dropped single-column
    #     merge_request_id index.
    #   - (issue_id, link_type): the issue/work-item-side readers and FK
    #     lookups (e.g. the work item development widget, count_for_issue),
    #     replacing the dropped single-column issue_id index.
    add_concurrent_index :merge_requests_closing_issues, [:merge_request_id, :link_type], name: MR_LINK_TYPE_INDEX
    add_concurrent_index :merge_requests_closing_issues, [:issue_id, :link_type], name: ISSUE_LINK_TYPE_INDEX

    # A single partial unique index enforces (merge_request_id, issue_id)
    # uniqueness at the DB level for every link type except closes (0).
    # Indexing the link_type column too keeps the constraint per-type (one
    # mentioned and one related may coexist for the same pair) and mirrors the
    # model validation scope [:issue_id, :link_type]. closes (0) is excluded
    # because production data already contains duplicate closes rows that
    # cannot be deduplicated here. `link_type <> 0` (rather than `IN (1, 2)`)
    # so any future link type is covered automatically.
    add_concurrent_index :merge_requests_closing_issues, [:merge_request_id, :issue_id, :link_type],
      unique: true, where: 'link_type <> 0', name: UNIQUE_INDEX
  end

  def down
    remove_concurrent_index_by_name :merge_requests_closing_issues, UNIQUE_INDEX
    remove_concurrent_index_by_name :merge_requests_closing_issues, MR_LINK_TYPE_INDEX
    remove_concurrent_index_by_name :merge_requests_closing_issues, ISSUE_LINK_TYPE_INDEX

    remove_column :merge_requests_closing_issues, :link_type, if_exists: true
  end
end
