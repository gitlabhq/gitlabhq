# frozen_string_literal: true

class CreateBillableUsageExportLogs < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  GENERATED_AT_INDEX = 'index_billable_usage_export_logs_on_generated_at'

  def change
    create_table :billable_usage_export_logs do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :generated_at, null: false
      t.bigint :generated_by_id
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.integer :record_count, null: false, default: 0
      t.text :payload_checksum, null: false, limit: 64

      t.check_constraint 'period_end >= period_start',
        name: 'check_billable_usage_export_logs_period_end_after_start'
      t.check_constraint 'record_count >= 0',
        name: 'check_billable_usage_export_logs_record_count_non_negative'
      t.check_constraint "payload_checksum ~ '^[0-9a-f]{64}$'",
        name: 'check_billable_usage_export_logs_payload_checksum_format'

      t.index :generated_at, name: GENERATED_AT_INDEX
      t.index :generated_by_id, name: 'index_billable_usage_export_logs_on_generated_by_id'
      t.index :payload_checksum, name: 'index_billable_usage_export_logs_on_payload_checksum'
    end
  end
end
