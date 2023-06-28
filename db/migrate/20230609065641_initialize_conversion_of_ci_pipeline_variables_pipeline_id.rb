# frozen_string_literal: true

class InitializeConversionOfCiPipelineVariablesPipelineId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE = :ci_pipeline_variables
  COLUMNS = %i[pipeline_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
