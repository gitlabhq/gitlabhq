# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMlCandidateParamsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ml_candidate_params_project_id
      feature_category :mlops
    end
  end
end
