# frozen_string_literal: true

class BackfillMergeRequestMetricsForBigintConversion < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE = :merge_request_metrics
  COLUMNS = %i[id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
