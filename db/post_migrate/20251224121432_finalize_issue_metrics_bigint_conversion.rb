# frozen_string_literal: true

class FinalizeIssueMetricsBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.9'

  TABLE = :issue_metrics
  COLUMNS = %i[id issue_id]

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(TABLE, COLUMNS)
  end

  def down
    # NO OP
  end
end
