# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiPipelineArtifactStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_p_ci_pipeline_artifact_states_project_id
      feature_category :geo_replication
    end
  end
end
