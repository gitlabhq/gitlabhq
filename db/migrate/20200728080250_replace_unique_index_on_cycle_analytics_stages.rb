# frozen_string_literal: true

class ReplaceUniqueIndexOnCycleAnalyticsStages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_analytics_ca_group_stages_on_group_id_and_name'
  NEW_INDEX_NAME = 'index_group_stages_on_group_id_group_value_stream_id_and_name'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:analytics_cycle_analytics_group_stages,
                         [:group_id, :group_value_stream_id, :name],
                         unique: true,
                         name: NEW_INDEX_NAME)

    remove_concurrent_index_by_name :analytics_cycle_analytics_group_stages, OLD_INDEX_NAME
  end

  def down
    # Removing duplicated records (group_id, name) that would prevent re-creating the old index.
    execute <<-SQL
      DELETE FROM analytics_cycle_analytics_group_stages
      USING (
        SELECT group_id, name, MIN(id) as min_id
        FROM analytics_cycle_analytics_group_stages
        GROUP BY group_id, name
        HAVING COUNT(id) > 1
      ) as analytics_cycle_analytics_group_stages_name_duplicates
      WHERE analytics_cycle_analytics_group_stages_name_duplicates.group_id = analytics_cycle_analytics_group_stages.group_id
      AND analytics_cycle_analytics_group_stages_name_duplicates.name = analytics_cycle_analytics_group_stages.name
      AND analytics_cycle_analytics_group_stages_name_duplicates.min_id <> analytics_cycle_analytics_group_stages.id
    SQL

    add_concurrent_index(:analytics_cycle_analytics_group_stages,
                         [:group_id, :name],
                         unique: true,
                         name: OLD_INDEX_NAME)

    remove_concurrent_index_by_name :analytics_cycle_analytics_group_stages, NEW_INDEX_NAME
  end
end
