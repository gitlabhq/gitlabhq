# frozen_string_literal: true

class InitializeConversionOfCiSourcesPipelinesToBigint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[id project_id source_project_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
