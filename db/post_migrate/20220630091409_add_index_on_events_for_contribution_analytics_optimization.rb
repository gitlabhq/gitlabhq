# frozen_string_literal: true

class AddIndexOnEventsForContributionAnalyticsOptimization < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_events_to_improve_contribution_analytics_performance'

  def up
    add_concurrent_index :events, [:project_id, :target_type, :action, :created_at, :author_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
