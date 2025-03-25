# frozen_string_literal: true

class CleanupDeleteOrphanedPartitionedCiRunnerMachineRecords < Gitlab::Database::Migration[2.2]
  MIGRATION = "DeleteOrphanedPartitionedCiRunnerMachineRecords"

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '17.11'

  def up
    delete_batched_background_migration(MIGRATION, :ci_runner_machines_687967fa8a, :runner_id, [])
  end

  def down; end
end
