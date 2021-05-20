# frozen_string_literal: true

class BackfillCiBuildTraceSectionsForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_build_trace_sections
  COLUMN = :build_id

  def up
    backfill_conversion_of_integer_to_bigint TABLE, COLUMN, batch_size: 15000, sub_batch_size: 100, primary_key: COLUMN
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint TABLE, COLUMN, primary_key: COLUMN
  end
end
