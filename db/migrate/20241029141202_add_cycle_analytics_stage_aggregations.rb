# frozen_string_literal: true

class AddCycleAnalyticsStageAggregations < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    create_table :analytics_cycle_analytics_stage_aggregations, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory name is cycle_analytics_stage_aggregation
      t.references :group, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.references :stage, references: :analytics_cycle_analytics_group_stages, null: false, index: false,
        foreign_key: { to_table: :analytics_cycle_analytics_group_stages, on_delete: :cascade }
      t.integer :runtimes_in_seconds, array: true, default: [], null: false
      t.integer :processed_records, array: true, default: [], null: false
      t.bigint :last_issues_id
      t.bigint :last_merge_requests_id

      t.datetime_with_timezone :last_run_at
      t.datetime_with_timezone :last_issues_updated_at
      t.datetime_with_timezone :last_merge_requests_updated_at
      t.datetime_with_timezone :last_completed_at

      t.boolean :enabled, default: true, null: false

      t.check_constraint 'CARDINALITY(runtimes_in_seconds) <= 10'
      t.check_constraint 'CARDINALITY(processed_records) <= 10'
    end

    execute("ALTER TABLE analytics_cycle_analytics_stage_aggregations ADD PRIMARY KEY (stage_id)")
  end

  def down
    drop_table :analytics_cycle_analytics_stage_aggregations
  end
end
