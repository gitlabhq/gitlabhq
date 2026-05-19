# frozen_string_literal: true

class ValidateClusterProvidersAwsShardingKeyConstraintFixed < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_6d49cca3b0'

  milestone '19.0'

  def up
    validate_multi_column_not_null_constraint :cluster_providers_aws,
      :organization_id, :group_id, :project_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
