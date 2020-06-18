# frozen_string_literal: true

class AddIndexOnStartingEndingAtToMetricsDashboardAnnotations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_metrics_dashboard_annotations_on_timespan_end'

  disable_ddl_transaction!

  def up
    add_concurrent_index :metrics_dashboard_annotations, 'COALESCE(ending_at, starting_at)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :metrics_dashboard_annotations, 'COALESCE(ending_at, starting_at)', name: INDEX_NAME
  end
end
