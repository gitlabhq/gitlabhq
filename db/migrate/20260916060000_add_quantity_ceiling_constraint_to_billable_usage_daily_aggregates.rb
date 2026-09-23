# frozen_string_literal: true

class AddQuantityCeilingConstraintToBillableUsageDailyAggregates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  TABLE_NAME = :billable_usage_daily_aggregates
  CONSTRAINT_NAME = 'check_billable_usage_daily_aggs_quantity_within_ceiling'

  def up
    # The com.gitlab/billable_usage Iglu schema caps quantity at this value in every
    # version, so a row above it cannot be exported. Writes accumulate into the day's
    # row, which means the ceiling has to hold for the stored total and not only for
    # the incoming event the model validates.
    add_check_constraint(TABLE_NAME, 'quantity <= 2147483647', CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end
end
