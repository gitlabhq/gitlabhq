# frozen_string_literal: true

class UpdateThrottleUnauthenticatedGitHttpInApplicationSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.0'

  disable_ddl_transaction!

  def up
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits_unauthenticated_git_http = jsonb_build_object(
        'throttle_unauthenticated_git_http_enabled', throttle_unauthenticated_enabled,
        'throttle_unauthenticated_git_http_requests_per_period', throttle_unauthenticated_requests_per_period,
        'throttle_unauthenticated_git_http_period_in_seconds', throttle_unauthenticated_period_in_seconds
      );
    SQL
  end

  def down
    execute "UPDATE application_settings SET rate_limits_unauthenticated_git_http = CAST('{}' AS jsonb)"
  end
end
