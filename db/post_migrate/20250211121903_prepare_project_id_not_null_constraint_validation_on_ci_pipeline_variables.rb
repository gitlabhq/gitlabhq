# frozen_string_literal: true

class PrepareProjectIdNotNullConstraintValidationOnCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  PARTITIONED_TABLE_NAME = :p_ci_pipeline_variables
  CONSTRAINT_NAME = 'check_6e932dbabf'

  def up
    prepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end
end
