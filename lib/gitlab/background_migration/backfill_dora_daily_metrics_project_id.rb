# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDoraDailyMetricsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dora_daily_metrics_project_id
      feature_category :continuous_delivery
    end
  end
end
