# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BatchedBackgroundMigrationsMetric < DatabaseMetric
          relation { Gitlab::Database::BackgroundMigration::BatchedMigration.with_status(:finished) }

          timestamp_column(:finished_at)

          operation :count

          def value
            relation.map do |batched_migration|
              {
                job_class_name: batched_migration.job_class_name,
                elapsed_time: batched_migration.finished_at.to_i - batched_migration.started_at.to_i
              }
            end
          end
        end
      end
    end
  end
end
