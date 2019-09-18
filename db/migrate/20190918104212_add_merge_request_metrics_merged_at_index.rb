# frozen_string_literal: true

class AddMergeRequestMetricsMergedAtIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_metrics, [:merged_at, :id]
  end

  def down
    remove_concurrent_index :merge_request_metrics, [:merged_at, :id]
  end
end
