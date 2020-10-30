# frozen_string_literal: true

class UpdateHistoricalDataRecordedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_value = Arel.sql("COALESCE(created_at, date + '12:00'::time AT TIME ZONE '#{Time.zone&.tzinfo&.name || "Etc/UTC"}')")

    update_column_in_batches(:historical_data, :recorded_at, update_value) do |table, query|
      query.where(table[:recorded_at].eq(nil))
    end

    add_not_null_constraint :historical_data, :recorded_at

    change_column_null :historical_data, :date, true
  end

  def down
    change_column_null :historical_data, :date, false

    remove_not_null_constraint :historical_data, :recorded_at

    update_column_in_batches(:historical_data, :recorded_at, nil) do |table, query|
      query.where(table[:recorded_at].not_eq(nil))
    end
  end
end
