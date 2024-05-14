# frozen_string_literal: true

class InsertActiveVersionedPagesDeploymentsLimitByNamespace < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.11'

  def up
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'premium', 100)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'premium_trial', 100)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'ultimate', 500)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'ultimate_trial', 500)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'default', 1000)
  end

  def down
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'premium', 0)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'premium_trial', 0)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'ultimate', 0)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'ultimate_trial', 0)
    create_or_update_plan_limit('active_versioned_pages_deployments_limit_by_namespace', 'default', 0)
  end
end
