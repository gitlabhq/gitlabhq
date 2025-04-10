# frozen_string_literal: true

class CleanupBackfillCiRunnerMachinesPartitionedTable < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  MIGRATION = 'BackfillCiRunnerMachinesPartitionedTable'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    delete_batched_background_migration(MIGRATION, :ci_runner_machines, :id, ['ci_runner_machines_687967fa8a'])
  end

  def down; end
end
