# frozen_string_literal: true

class BackfillGeoCiJobArtifactVerificationSummaries < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BUCKET_COUNT = 100_000

  def up
    execute(<<~SQL.squish)
      INSERT INTO geo_ci_job_artifact_verification_summaries
        (bucket_number, total_count, verified_count, failed_count, state, state_changed_at, created_at, updated_at)
      SELECT n, 0, 0, 0, 1, NOW(), NOW(), NOW()
      FROM generate_series(0, #{BUCKET_COUNT - 1}) AS s(n)
      ON CONFLICT (bucket_number) DO NOTHING
    SQL
  end

  def down
    execute('DELETE FROM geo_ci_job_artifact_verification_summaries')
  end
end
