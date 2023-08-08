# frozen_string_literal: true

class InitializeConversionOfCiSourcesPipelinesSource < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[pipeline_id source_pipeline_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
