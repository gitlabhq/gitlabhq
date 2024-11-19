# frozen_string_literal: true

class PrepareProjectIdNotNullValidationOnCiStages < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  PARTITIONED_TABLE_NAME = :p_ci_stages
  CONSTRAINT_NAME = 'check_74835fc631'

  def up
    prepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
  end
end
