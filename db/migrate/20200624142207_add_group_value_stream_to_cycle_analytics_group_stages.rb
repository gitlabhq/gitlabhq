# frozen_string_literal: true

class AddGroupValueStreamToCycleAnalyticsGroupStages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :analytics_cycle_analytics_group_stages, :group_value_stream_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :analytics_cycle_analytics_group_stages, :group_value_stream_id
    end
  end
end
