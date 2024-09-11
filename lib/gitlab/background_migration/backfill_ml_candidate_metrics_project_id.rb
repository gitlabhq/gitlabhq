# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMlCandidateMetricsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ml_candidate_metrics_project_id
      feature_category :mlops
    end
  end
end
