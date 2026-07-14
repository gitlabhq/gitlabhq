# frozen_string_literal: true

class SeedCiLintLimitPerUserFromPipelineLimit < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '19.2'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits = jsonb_set(
        rate_limits,
        '{ci_lint_limit_per_user}',
        rate_limits->'pipeline_limit_per_user'
      )
      WHERE COALESCE((rate_limits->>'pipeline_limit_per_user')::int, 0) > 0
        AND COALESCE((rate_limits->>'ci_lint_limit_per_user')::int, 0) = 0
    SQL
  end

  def down
    # ci_lint_limit_per_user did not exist before this migration, so the true
    # reversal is to remove the key entirely. We cannot reliably tell a seeded
    # value apart from one an admin set independently after the migration, so we
    # remove the key in all cases rather than guessing via value equality.
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits = rate_limits - 'ci_lint_limit_per_user'
      WHERE rate_limits ? 'ci_lint_limit_per_user'
    SQL
  end
end
