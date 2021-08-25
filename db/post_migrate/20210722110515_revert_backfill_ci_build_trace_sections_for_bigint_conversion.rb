# frozen_string_literal: true

class RevertBackfillCiBuildTraceSectionsForBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_build_trace_sections
  COLUMN = :build_id

  def up
    revert_backfill_conversion_of_integer_to_bigint TABLE, COLUMN, primary_key: COLUMN
  end

  def down
    # no-op
  end
end
