# frozen_string_literal: true

class CreateBillableUsageDailyAggregates < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  UNIQUE_INDEX_NAME = 'index_billable_usage_daily_aggs_on_unique_tuple'
  UUID_INDEX_NAME = 'index_billable_usage_daily_aggs_on_event_aggregate_uuid'

  def change
    create_table :billable_usage_daily_aggregates do |t|
      # Unique across every instance: CustomersDot dedupes uploads on this value alone.
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
      t.check_constraint 'events_count >= 0',
        name: 'check_billable_usage_daily_aggs_events_count_non_negative'

      # NULLS NOT DISTINCT so nullable parts of the key still collide on upsert.
      t.index %i[usage_date event_type feature_qualified_name root_namespace_id operation_type],
        unique: true, nulls_not_distinct: true, name: UNIQUE_INDEX_NAME

      t.index :event_aggregate_uuid, unique: true, name: UUID_INDEX_NAME
    end
  end
end
