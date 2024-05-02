# frozen_string_literal: true

class InsertActiveVersionedPagesDeploymentsLimitByNamespaceForGoldPlan < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.0'

  def up
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'silver', 100)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'gold', 500)
  end

  def down
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'silver', 0)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'gold', 0)
  end
end
