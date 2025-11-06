# frozen_string_literal: true

class BackFillIssueMetricsForBigIntConversion < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.6'

  TABLE = :issue_metrics
  COLUMNS = %i[id issue_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
