# frozen_string_literal: true

class ScheduleIndexOnEventsForContributionAnalyticsOptimization < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_on_events_to_improve_contribution_analytics_performance'

  def up
    prepare_async_index :events, [:project_id, :target_type, :action, :created_at, :author_id, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, INDEX_NAME
  end
end
