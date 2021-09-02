# frozen_string_literal: true

class CreateAnalyticsCycleAnalyticsIssueStageEvents < ActiveRecord::Migration[6.1]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers
  include Gitlab::Database::MigrationHelpers

  def up
    execute <<~SQL
    CREATE TABLE analytics_cycle_analytics_issue_stage_events (
      stage_event_hash_id integer NOT NULL,
      issue_id integer NOT NULL,
      group_id integer NOT NULL,
      project_id integer NOT NULL,
      milestone_id integer,
      author_id integer,
      start_event_timestamp timestamp with time zone NOT NULL,
      end_event_timestamp timestamp with time zone,
      PRIMARY KEY (stage_event_hash_id, issue_id)
    ) PARTITION BY HASH (stage_event_hash_id)
    SQL

    create_hash_partitions :analytics_cycle_analytics_issue_stage_events, 32
  end

  def down
    drop_table :analytics_cycle_analytics_issue_stage_events
  end
end
