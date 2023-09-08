# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BatchedBackgroundMigrationFailedJobsMetric < DatabaseMetric
          relation do
            Gitlab::Database::BackgroundMigration::BatchedMigration
              .joins(:batched_jobs)
              .where(batched_jobs: { status: '2' })
              .group(%w[table_name job_class_name])
              .order(%w[table_name job_class_name])
              .select(['table_name', 'job_class_name', 'COUNT(batched_jobs) AS number_of_failed_jobs'])
          end

          timestamp_column(:created_at)

          operation :count

          def value
            relation.map do |batched_migration|
              {
                job_class_name: batched_migration.job_class_name,
                table_name: batched_migration.table_name,
                number_of_failed_jobs: batched_migration.number_of_failed_jobs
              }
            end
          end

          def to_sql
            relation.unscope(:order).to_sql
          end
        end
      end
    end
  end
end
