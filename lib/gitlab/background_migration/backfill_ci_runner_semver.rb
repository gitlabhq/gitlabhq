# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to update semver column in ci_runners in batches based on existing version values
    class BackfillCiRunnerSemver < Gitlab::BackgroundMigration::BatchedMigrationJob
      def perform
        each_sub_batch(
          operation_name: :backfill_ci_runner_semver,
          batching_scope: ->(relation) { relation.where('semver::cidr IS NULL') }
        ) do |sub_batch|
          ranged_query = sub_batch.select(
            %q(id AS r_id,
               substring(ci_runners.version FROM 'v?(\d+\.\d+\.\d+)') AS extracted_semver)
          )

          update_sql = <<~SQL
            UPDATE
              ci_runners
            SET semver = extracted_semver
            FROM (#{ranged_query.to_sql}) v
            WHERE id = v.r_id
              AND v.extracted_semver IS NOT NULL
          SQL

          connection.execute(update_sql)
        end
      end
    end
  end
end
