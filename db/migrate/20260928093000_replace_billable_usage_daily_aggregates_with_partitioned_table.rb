# frozen_string_literal: true

class ReplaceBillableUsageDailyAggregatesWithPartitionedTable < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  OLD_TABLE_NAME = :billable_usage_daily_aggregates
  NEW_TABLE_NAME = :billable_usage_daily_namespace_aggregates

  # rubocop:disable Migration/DropTable -- The old table is empty everywhere: it is only
  # written behind feature flags on air-gapped instances and has no readers yet.
  def up
    drop_table OLD_TABLE_NAME, if_exists: true

    create_table NEW_TABLE_NAME,
      primary_key: [:id, :usage_date],
      options: 'PARTITION BY RANGE (usage_date)',
      if_not_exists: true do |t|
      t.bigserial :id, null: false
      t.timestamps_with_timezone null: false
      t.bigint :events_count, null: false, default: 0
      t.bigint :root_namespace_id
      t.date :usage_date, null: false
      t.integer :schema_version, limit: 2, null: false, default: 1
      t.decimal :quantity, precision: 14, scale: 4, null: false
      t.text :event_type, null: false, limit: 255
      t.text :unit_of_measure, null: false, limit: 64
      t.text :feature_qualified_name, null: false, limit: 255
      t.text :operation_type, limit: 64

      t.check_constraint 'quantity >= 0',
        name: 'check_billable_usage_daily_ns_aggs_quantity_non_negative'
      t.check_constraint 'quantity <= 2147483647',
        name: 'check_billable_usage_daily_ns_aggs_quantity_within_ceiling'
      t.check_constraint 'events_count >= 0',
        name: 'check_billable_usage_daily_ns_aggs_events_count_non_negative'

      t.index %i[usage_date event_type feature_qualified_name operation_type root_namespace_id],
        unique: true, nulls_not_distinct: true, name: 'index_billable_usage_daily_ns_aggs_on_unique_tuple'
    end
  end

  def down
    drop_table NEW_TABLE_NAME, if_exists: true

    create_table OLD_TABLE_NAME, if_not_exists: true do |t|
      t.uuid :event_aggregate_uuid, null: false
      t.timestamps_with_timezone null: false
      t.bigint :events_count, null: false, default: 0
      t.bigint :root_namespace_id
      t.date :usage_date, null: false
      t.integer :schema_version, limit: 2, null: false, default: 1
      t.decimal :quantity, precision: 14, scale: 4, null: false
      t.text :event_type, null: false, limit: 255
      t.text :unit_of_measure, null: false, limit: 64
      t.text :feature_qualified_name, null: false, limit: 255
      t.text :operation_type, limit: 64

      t.check_constraint 'quantity >= 0',
        name: 'check_billable_usage_daily_aggs_quantity_non_negative'
      t.check_constraint 'quantity <= 2147483647',
        name: 'check_billable_usage_daily_aggs_quantity_within_ceiling'
      t.check_constraint 'events_count >= 0',
        name: 'check_billable_usage_daily_aggs_events_count_non_negative'

      t.index %i[usage_date event_type feature_qualified_name root_namespace_id operation_type],
        unique: true, nulls_not_distinct: true, name: 'index_billable_usage_daily_aggs_on_unique_tuple'

      t.index :event_aggregate_uuid, unique: true, name: 'index_billable_usage_daily_aggs_on_event_aggregate_uuid'
    end
  end
  # rubocop:enable Migration/DropTable
end
