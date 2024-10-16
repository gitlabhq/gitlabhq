# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillContainerRepositoryStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_container_repository_states_project_id
      feature_category :geo_replication
    end
  end
end
