# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillDoraDailyMetricsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dora_daily_metrics_project_id
      feature_category :continuous_delivery
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
