# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiJobArtifactStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_job_artifact_states_project_id
      feature_category :geo_replication
    end
  end
end
