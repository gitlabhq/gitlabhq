# frozen_string_literal: true

class CleanupRequeueDeleteOrphanedPartitionedCiRunnerMachineRecords < Gitlab::Database::Migration[2.2]
  MIGRATION = "RequeueDeleteOrphanedPartitionedCiRunnerMachineRecords"

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '17.10'

  def up
    delete_batched_background_migration(MIGRATION, :ci_runner_machines_687967fa8a, :runner_id, [])
  end

  def down; end
end
