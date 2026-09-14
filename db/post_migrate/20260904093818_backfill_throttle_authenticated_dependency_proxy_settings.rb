# frozen_string_literal: true

class BackfillThrottleAuthenticatedDependencyProxySettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits = COALESCE(rate_limits, '{}'::jsonb) ||
        jsonb_build_object(
          'throttle_authenticated_dependency_proxy_enabled', true,
          'throttle_authenticated_dependency_proxy_requests_per_period', throttle_authenticated_web_requests_per_period,
          'throttle_authenticated_dependency_proxy_period_in_seconds', throttle_authenticated_web_period_in_seconds
        )
      WHERE throttle_authenticated_web_enabled = true
        AND (rate_limits->>'throttle_authenticated_dependency_proxy_enabled' IS NULL
             OR (rate_limits->>'throttle_authenticated_dependency_proxy_enabled')::boolean = false)
    SQL
  end

  def down
    # No-op: We don't want to remove settings that may have been manually configured
  end
end
