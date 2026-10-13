# frozen_string_literal: true

class CreateBillableUsageDailyTotals < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    create_table :billable_usage_daily_totals do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :source_updated_at, null: false
      t.bigint :events_count, null: false, default: 0
      t.date :usage_date, null: false
      t.integer :schema_version, limit: 2, null: false, default: 1
      t.decimal :quantity, precision: 20, scale: 4, null: false
      t.text :event_type, null: false, limit: 255
      t.text :unit_of_measure, null: false, limit: 64
      t.text :feature_qualified_name, null: false, limit: 255
      t.text :operation_type, limit: 64

      t.check_constraint 'quantity >= 0', name: 'check_billable_usage_daily_totals_quantity_non_negative'
      t.check_constraint 'events_count >= 0', name: 'check_billable_usage_daily_totals_events_count_non_negative'

      t.index %i[usage_date event_type feature_qualified_name operation_type],
        unique: true, nulls_not_distinct: true, name: 'index_billable_usage_daily_totals_on_unique_tuple'
    end
  end
end
