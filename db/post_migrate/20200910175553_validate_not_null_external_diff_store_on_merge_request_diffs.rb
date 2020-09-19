# frozen_string_literal: true

class ValidateNotNullExternalDiffStoreOnMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Remove index which was only added to fill external_diff_store
  INDEX_NAME = 'index_merge_request_diffs_external_diff_store_is_null'
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :merge_request_diffs, :external_diff_store

    remove_concurrent_index_by_name :merge_request_diffs, INDEX_NAME
  end

  def down
    add_concurrent_index :merge_request_diffs, :id, where: 'external_diff_store IS NULL', name: INDEX_NAME
  end
end
