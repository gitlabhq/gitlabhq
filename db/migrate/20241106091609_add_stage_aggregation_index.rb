# frozen_string_literal: true

class AddStageAggregationIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = 'index_ca_enabled_incomplete_aggregation_stages_on_last_run_at'

  def up
    add_concurrent_index(
      :analytics_cycle_analytics_stage_aggregations,
      :last_run_at,
      where: "last_completed_at IS NULL AND enabled = TRUE",
      order: 'NULLS FIRST',
      name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:analytics_cycle_analytics_stage_aggregations, INDEX_NAME)
  end
end
