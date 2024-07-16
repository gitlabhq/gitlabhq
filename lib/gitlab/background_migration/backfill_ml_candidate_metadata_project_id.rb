# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMlCandidateMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ml_candidate_metadata_project_id
      feature_category :mlops
    end
  end
end
