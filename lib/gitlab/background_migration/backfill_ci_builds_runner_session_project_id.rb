# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiBuildsRunnerSessionProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_builds_runner_session_project_id
      feature_category :runner_core
    end
  end
end
