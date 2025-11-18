# frozen_string_literal: true

class InitializeConversionOfIssueMetricsIdToBigInt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  TABLE = :issue_metrics
  COLUMNS = %i[id issue_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
