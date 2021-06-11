# frozen_string_literal: true

class AddVerificationIndexesToMergeRequestDiffDetailsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  VERIFICATION_STATE_INDEX_NAME = "index_merge_request_diff_details_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "index_merge_request_diff_details_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "index_merge_request_diff_details_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "index_merge_request_diff_details_needs_verification"

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_diff_details, :verification_state, name: VERIFICATION_STATE_INDEX_NAME
    add_concurrent_index :merge_request_diff_details, :verified_at, where: "(verification_state = 0)", order: { verified_at: 'ASC NULLS FIRST' }, name: PENDING_VERIFICATION_INDEX_NAME
    add_concurrent_index :merge_request_diff_details, :verification_retry_at, where: "(verification_state = 3)", order: { verification_retry_at: 'ASC NULLS FIRST' }, name: FAILED_VERIFICATION_INDEX_NAME
    add_concurrent_index :merge_request_diff_details, :verification_state, where: "(verification_state = 0 OR verification_state = 3)", name: NEEDS_VERIFICATION_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_diff_details, VERIFICATION_STATE_INDEX_NAME
    remove_concurrent_index_by_name :merge_request_diff_details, PENDING_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name :merge_request_diff_details, FAILED_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name :merge_request_diff_details, NEEDS_VERIFICATION_INDEX_NAME
  end
end
