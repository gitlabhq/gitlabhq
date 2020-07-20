# frozen_string_literal: true

class DropOldNonUniqueIndexOnMrMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_merge_request_metrics'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:merge_request_metrics, INDEX_NAME)
  end

  def down
    add_concurrent_index :merge_request_metrics, :merge_request_id, name: INDEX_NAME
  end
end
