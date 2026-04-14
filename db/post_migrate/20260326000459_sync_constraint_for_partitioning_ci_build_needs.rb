# frozen_string_literal: true

class SyncConstraintForPartitioningCiBuildNeeds < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  TABLE_NAME = :ci_build_needs
  CONSTRAINT_NAME = :partitioning_constraint

  def up
    validate_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
