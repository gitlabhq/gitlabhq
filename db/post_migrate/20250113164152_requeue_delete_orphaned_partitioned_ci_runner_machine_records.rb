# frozen_string_literal: true

class RequeueDeleteOrphanedPartitionedCiRunnerMachineRecords < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "RequeueDeleteOrphanedPartitionedCiRunnerMachineRecords"

  def up
    # no-oped and deleted in 20250307070001_cleanup_requeue_delete_orphaned_partitioned_ci_runner_machine_records.rb
    # since this can collide with 20250307080000_replace_ci_runners_machines_with_partitioned_table which
    # is scheduled for 17.10 (no required stop between them)
  end

  def down
    # no-op
  end
end
