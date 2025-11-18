# frozen_string_literal: true

class AddJiraTrackerDataIndexOnNullShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_jira_tracker_data_on_null_sharding_key'

  def up
    add_concurrent_index(
      :jira_tracker_data,
      :id,
      where: 'project_id IS NULL AND group_id IS NULL AND organization_id IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :jira_tracker_data, INDEX_NAME
  end
end
