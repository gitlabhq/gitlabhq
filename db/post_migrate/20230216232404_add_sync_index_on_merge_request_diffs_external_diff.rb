# frozen_string_literal: true

class AddSyncIndexOnMergeRequestDiffsExternalDiff < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_merge_request_diffs_on_external_diff'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_diffs, :external_diff, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_diffs, INDEX_NAME
  end
end
