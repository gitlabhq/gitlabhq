# frozen_string_literal: true

class RemoveRedundantIndexOnMergeRequestContextCommitDiffFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_request_context_commit_diff_files, 'idx_mr_cc_diff_files_on_mr_cc_id'
  end

  def down
    # no-op: this index is not tracked in structure.sql, and is redundant due to idx_mr_cc_diff_files_on_mr_cc_id_and_sha
  end
end
