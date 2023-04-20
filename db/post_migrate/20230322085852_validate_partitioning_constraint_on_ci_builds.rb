# frozen_string_literal: true

class ValidatePartitioningConstraintOnCiBuilds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    validate_check_constraint :ci_builds, :partitioning_constraint
  end

  # No-op
  def down; end
end
