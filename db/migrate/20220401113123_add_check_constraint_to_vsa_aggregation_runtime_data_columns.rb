# frozen_string_literal: true

class AddCheckConstraintToVsaAggregationRuntimeDataColumns < Gitlab::Database::Migration[1.0]
  FULL_RUNTIMES_IN_SECONDS_CONSTRAINT = 'full_runtimes_in_seconds_size'
  FULL_PROCESSED_RECORDS_CONSTRAINT = 'full_processed_records_size'

  disable_ddl_transaction!

  def up
    add_check_constraint(:analytics_cycle_analytics_aggregations,
                         'CARDINALITY(full_runtimes_in_seconds) <= 10',
                         FULL_RUNTIMES_IN_SECONDS_CONSTRAINT)

    add_check_constraint(:analytics_cycle_analytics_aggregations,
                         'CARDINALITY(full_processed_records) <= 10',
                         FULL_PROCESSED_RECORDS_CONSTRAINT)
  end

  def down
    remove_check_constraint :analytics_cycle_analytics_aggregations, FULL_RUNTIMES_IN_SECONDS_CONSTRAINT
    remove_check_constraint :analytics_cycle_analytics_aggregations, FULL_PROCESSED_RECORDS_CONSTRAINT
  end
end
