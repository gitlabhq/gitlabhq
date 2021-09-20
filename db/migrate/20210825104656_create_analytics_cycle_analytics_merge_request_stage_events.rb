# frozen_string_literal: true

class CreateAnalyticsCycleAnalyticsMergeRequestStageEvents < ActiveRecord::Migration[6.1]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers
  include Gitlab::Database::MigrationHelpers

  def up
    execute <<~SQL
    CREATE TABLE analytics_cycle_analytics_merge_request_stage_events (
      stage_event_hash_id bigint NOT NULL,
      merge_request_id bigint NOT NULL,
      group_id bigint NOT NULL,
      project_id bigint NOT NULL,
      milestone_id bigint,
      author_id bigint,
      start_event_timestamp timestamp with time zone NOT NULL,
      end_event_timestamp timestamp with time zone,
      PRIMARY KEY (stage_event_hash_id, merge_request_id)
    ) PARTITION BY HASH (stage_event_hash_id)
    SQL

    create_hash_partitions :analytics_cycle_analytics_merge_request_stage_events, 32
  end

  def down
    drop_table :analytics_cycle_analytics_merge_request_stage_events
  end
end
