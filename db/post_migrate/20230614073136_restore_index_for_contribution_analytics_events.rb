# frozen_string_literal: true

class RestoreIndexForContributionAnalyticsEvents < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_on_events_to_improve_contribution_analytics_performance'

  disable_ddl_transaction!

  def up
    prepare_async_index :events, %i[project_id target_type action created_at author_id id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, %i[project_id target_type action created_at author_id id], name: INDEX_NAME
  end
end
