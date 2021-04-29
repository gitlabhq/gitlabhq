# frozen_string_literal: true

class BackfillCiBuildTraceChunksForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_build_trace_chunks
  COLUMNS = %i(build_id)

  def up
    return unless should_run?

    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    return unless should_run?

    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  private

  def should_run?
    Gitlab.dev_or_test_env? || Gitlab.com?
  end
end
