# frozen_string_literal: true

class ReplaceIndexOnMetricsMergedAt < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_metrics, :merged_at
    remove_concurrent_index :merge_request_metrics, [:merged_at, :id]
  end

  def down
    add_concurrent_index :merge_request_metrics, [:merged_at, :id]
    remove_concurrent_index :merge_request_metrics, :merged_at
  end
end
