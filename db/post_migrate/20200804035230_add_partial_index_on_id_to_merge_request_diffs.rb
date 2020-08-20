# frozen_string_literal: true

class AddPartialIndexOnIdToMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_merge_request_diffs_external_diff_store_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_diffs, :id, where: 'external_diff_store IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_diffs, INDEX_NAME
  end
end
