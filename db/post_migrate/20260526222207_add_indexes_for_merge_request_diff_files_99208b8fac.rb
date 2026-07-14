# frozen_string_literal: true

class AddIndexesForMergeRequestDiffFiles99208b8fac < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.2'
  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_files_99208b8fac
  PROJECT_ID_INDEX_NAME = 'index_merge_request_diff_files_99208b8fac_on_project_id'
  MR_DIFF_ID_INDEX_NAME = 'index_merge_request_diff_files_99208b8fac_on_mr_diff_id'

  def up
    # These indexes were created asynchronously on GitLab.com via
    # 20260416134655_prepare_async_indexes_for_merge_request_diff_files_99208b8fac.rb
    # but self-managed instances don't run async index creation.
    #
    # These indexes are required for the FK migration that follows
    # (20260526222208_add_fk_to_merge_request_diff_files_99208b8fac_retry.rb)
    # to avoid lock timeouts during FK constraint checks.
    add_concurrent_partitioned_index TABLE_NAME, :project_id, name: PROJECT_ID_INDEX_NAME
    add_concurrent_partitioned_index TABLE_NAME, :merge_request_diff_id, name: MR_DIFF_ID_INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE_NAME, PROJECT_ID_INDEX_NAME
    remove_concurrent_partitioned_index_by_name TABLE_NAME, MR_DIFF_ID_INDEX_NAME
  end
end
