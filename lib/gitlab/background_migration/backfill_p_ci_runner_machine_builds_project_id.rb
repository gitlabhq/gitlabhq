# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiRunnerMachineBuildsProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_p_ci_runner_machine_builds_project_id
      feature_category :fleet_visibility

      scope_to ->(relation) { relation }

      # NOTE: Moving scope to sub-batch scope since we're missing an index on project_id, build_id
      def perform
        each_sub_batch do |sub_batch|
          sub_batch.connection.execute(construct_query(sub_batch: sub_batch.where(backfill_column => nil)))
        end
      end
    end
  end
end
