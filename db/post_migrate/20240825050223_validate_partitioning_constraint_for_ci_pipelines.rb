# frozen_string_literal: true

class ValidatePartitioningConstraintForCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :ci_pipelines
  CONSTRAINT_NAME = :partitioning_constraint

  def up
    validate_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
