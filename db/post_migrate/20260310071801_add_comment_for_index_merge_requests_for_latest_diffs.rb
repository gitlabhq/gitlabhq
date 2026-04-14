# frozen_string_literal: true

class AddCommentForIndexMergeRequestsForLatestDiffs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '18.10'

  INDEX_NAME = 'index_on_merge_requests_for_latest_diffs'
  INDEX_COMMENT = 'Index used to efficiently obtain the oldest merge request for a commit SHA'

  def up
    return unless merge_requests_for_latest_diffs_exists?

    execute "COMMENT ON INDEX #{merge_requests_for_latest_diffs_bigint_name} IS '#{INDEX_COMMENT}'"
  end

  def down
    return unless merge_requests_for_latest_diffs_exists?

    execute "COMMENT ON INDEX #{bigint_index_name(INDEX_NAME)} IS NULL"
  end

  private

  def merge_requests_for_latest_diffs_exists?
    index_exists_by_name?(:merge_requests, merge_requests_for_latest_diffs_bigint_name)
  end

  def merge_requests_for_latest_diffs_bigint_name
    bigint_index_name(INDEX_NAME)
  end
end
