# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiRunnerMachineBuildsProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_p_ci_runner_machine_builds_project_id
      feature_category :fleet_visibility
    end
  end
end
