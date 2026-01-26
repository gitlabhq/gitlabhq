# frozen_string_literal: true

class CreateBigintIndexesForIssueMetrics < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '18.9'
  disable_ddl_transaction!

  TABLE = :issue_metrics
  COLUMNS = %i[id issue_id]

  def up
    COLUMNS.each do |int_column|
      add_bigint_column_indexes(TABLE, int_column)
    end
  end

  def down
    drop_bigint_columns_indexes(TABLE, COLUMNS)
  end
end
