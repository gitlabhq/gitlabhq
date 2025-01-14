# frozen_string_literal: true

# We only want to run once the migration that backfills ci_runners_e59bb2812d
# has completed. This migration then deletes all ci_runner_machines_687967fa8a records
# that don't have a matching ci_runners_e59bb2812d record
class QueueDeleteOrphanedPCiRunnerMachineRecordsOnDotCom < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "DeleteOrphanedPartitionedCiRunnerMachineRecords"

  def up
    # no-op because the original migration was run before the check constraint was added.
    # The migration is being requeued by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176702
  end

  def down
    # no-op because the original migration was run before the check constraint was added.
    # The migration is being requeued by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176702
  end
end
