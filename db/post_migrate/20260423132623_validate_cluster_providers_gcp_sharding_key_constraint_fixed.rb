# frozen_string_literal: true

class ValidateClusterProvidersGcpShardingKeyConstraintFixed < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_a92783b0a9'

  milestone '19.0'

  def up
    validate_multi_column_not_null_constraint :cluster_providers_gcp,
      :organization_id, :group_id, :project_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
