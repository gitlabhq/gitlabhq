# frozen_string_literal: true

class InitializeConversionOfAbuseReportsToBigint < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE_NAME = :abuse_reports
  COLUMNS = %i[assignee_id id reporter_id resolved_by_id user_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS, primary_key: :id)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS)
  end
end
