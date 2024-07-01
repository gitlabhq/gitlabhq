# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class QueueBackfillAutocancelPartitionIdOnCiPipelines < BatchedMigrationJob
      operation_name :update_all
      feature_category :ci_scaling

      # rubocop:disable Layout/LineLength -- Improve readability
      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where.not(auto_canceled_by_id: nil)
            .where('ci_pipelines.auto_canceled_by_id = canceling_pipelines.id')
            .update_all('auto_canceled_by_partition_id = canceling_pipelines.partition_id FROM ci_pipelines as canceling_pipelines')
        end
      end
      # rubocop:enable Layout/LineLength
    end
  end
end
