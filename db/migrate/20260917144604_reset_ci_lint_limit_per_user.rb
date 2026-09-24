# frozen_string_literal: true

class ResetCiLintLimitPerUser < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '19.5'

  # Runs as a regular migration, not post-deployment, so the reset can't be
  # outrun by newly deployed code enforcing the limit before it runs.
  def up
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits = jsonb_set(
        rate_limits,
        '{ci_lint_limit_per_user}',
        '0'
      )
      WHERE COALESCE((rate_limits->>'ci_lint_limit_per_user')::int, 0) != 0
    SQL
  end

  def down
    # No-op: the per-instance values this migration overwrites aren't recorded
    # anywhere, so they can't be restored. Re-seeding from pipeline_limit_per_user
    # would just reinstate the limits this migration exists to clear.
  end
end
