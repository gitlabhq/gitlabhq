# frozen_string_literal: true

class AddActiveVersionedPagesDeploymentsLimitByNamespaceToPlanLimits < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column(
      :plan_limits,
      :active_versioned_pages_deployments_limit_by_namespace,
      :integer,
      default: 0,
      null: false
    )
  end
end
