# frozen_string_literal: true

class AddDiffTypeToMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  UNIQUE_INDEX_NAME = 'index_merge_request_diffs_on_unique_merge_request_id'

  def up
    unless column_exists?(:merge_request_diffs, :diff_type)
      with_lock_retries do
        add_column :merge_request_diffs, :diff_type, :integer, null: false, limit: 2, default: 1
      end
    end

    add_concurrent_index :merge_request_diffs, :merge_request_id, unique: true, where: 'diff_type = 2', name: UNIQUE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:merge_request_diffs, UNIQUE_INDEX_NAME)

    if column_exists?(:merge_request_diffs, :diff_type)
      with_lock_retries do
        remove_column :merge_request_diffs, :diff_type
      end
    end
  end
end
