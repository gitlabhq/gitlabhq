# frozen_string_literal: true

class BackfillAbuseReportsForBigintConversion < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_clusterwide

  TABLE_NAME = :abuse_reports
  COLUMNS = %i[assignee_id id reporter_id resolved_by_id user_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS, primary_key: :id)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS)
  end
end
