# frozen_string_literal: true

class CreateBigintIndexesForCiSourcesPipelines < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '19.3'
  disable_ddl_transaction!

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[id project_id source_project_id]

  def up
    COLUMNS.each do |int_column|
      add_bigint_column_indexes(TABLE, int_column)
    end
  end

  def down
    drop_bigint_columns_indexes(TABLE, COLUMNS)
  end
end
