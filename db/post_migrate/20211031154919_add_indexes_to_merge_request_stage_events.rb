# frozen_string_literal: true

class AddIndexesToMergeRequestStageEvents < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  GROUP_INDEX_NAME = 'index_merge_request_stage_events_group_duration'
  GROUP_IN_PROGRESS_INDEX_NAME = 'index_merge_request_stage_events_group_in_progress_duration'
  PROJECT_INDEX_NAME = 'index_merge_request_stage_events_project_duration'
  PROJECT_IN_PROGRESS_INDEX_NAME = 'index_merge_request_stage_events_project_in_progress_duration'

  def up
    add_concurrent_partitioned_index :analytics_cycle_analytics_merge_request_stage_events,
      'stage_event_hash_id, group_id, end_event_timestamp, merge_request_id, start_event_timestamp',
      where: 'end_event_timestamp IS NOT NULL',
      name: GROUP_INDEX_NAME

    add_concurrent_partitioned_index :analytics_cycle_analytics_merge_request_stage_events,
      'stage_event_hash_id, project_id, end_event_timestamp, merge_request_id, start_event_timestamp',
      where: 'end_event_timestamp IS NOT NULL',
      name: PROJECT_INDEX_NAME

    add_concurrent_partitioned_index :analytics_cycle_analytics_merge_request_stage_events,
      'stage_event_hash_id, group_id, start_event_timestamp, merge_request_id',
      where: 'end_event_timestamp IS NULL AND state_id = 1',
      name: GROUP_IN_PROGRESS_INDEX_NAME

    add_concurrent_partitioned_index :analytics_cycle_analytics_merge_request_stage_events,
      'stage_event_hash_id, project_id, start_event_timestamp, merge_request_id',
      where: 'end_event_timestamp IS NULL AND state_id = 1',
      name: PROJECT_IN_PROGRESS_INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :analytics_cycle_analytics_merge_request_stage_events, GROUP_INDEX_NAME
    remove_concurrent_partitioned_index_by_name :analytics_cycle_analytics_merge_request_stage_events, PROJECT_INDEX_NAME
    remove_concurrent_partitioned_index_by_name :analytics_cycle_analytics_merge_request_stage_events, GROUP_IN_PROGRESS_INDEX_NAME
    remove_concurrent_partitioned_index_by_name :analytics_cycle_analytics_merge_request_stage_events, PROJECT_IN_PROGRESS_INDEX_NAME
  end
end
