# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPagesDeploymentStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_pages_deployment_states_project_id
      feature_category :pages
    end
  end
end
