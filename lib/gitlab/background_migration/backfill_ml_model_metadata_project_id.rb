# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMlModelMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ml_model_metadata_project_id
      feature_category :mlops
    end
  end
end
