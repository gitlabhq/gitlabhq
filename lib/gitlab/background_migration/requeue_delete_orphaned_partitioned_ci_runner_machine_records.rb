# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- DeleteOrphanedPartitionedCiRunnerMachineRecords inherits from BatchedMigrationJob.
    class RequeueDeleteOrphanedPartitionedCiRunnerMachineRecords < DeleteOrphanedPartitionedCiRunnerMachineRecords
      operation_name :requeue_delete_orphaned_partitioned_ci_runner_machine_records
      feature_category :fleet_visibility
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
