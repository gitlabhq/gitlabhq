# frozen_string_literal: true

class ChangeDefaultActiveVersionedPagesDeploymentLimit < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    change_column_default(:plan_limits, :active_versioned_pages_deployments_limit_by_namespace, 1000)
  end

  def down
    change_column_default(:plan_limits, :active_versioned_pages_deployments_limit_by_namespace, 0)
  end
end
