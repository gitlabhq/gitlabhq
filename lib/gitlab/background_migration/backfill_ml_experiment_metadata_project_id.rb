# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMlExperimentMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ml_experiment_metadata_project_id
      feature_category :mlops
    end
  end
end
