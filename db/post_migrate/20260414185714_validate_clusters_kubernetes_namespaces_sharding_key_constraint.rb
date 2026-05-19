# frozen_string_literal: true

class ValidateClustersKubernetesNamespacesShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_8556b17a2a'

  milestone '19.0'

  def up
    validate_multi_column_not_null_constraint :clusters_kubernetes_namespaces,
      :organization_id, :group_id, :sharding_project_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
