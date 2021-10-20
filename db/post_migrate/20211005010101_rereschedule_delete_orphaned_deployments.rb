# frozen_string_literal: true

class RerescheduleDeleteOrphanedDeployments < Gitlab::Database::Migration[1.0]
  MIGRATION = 'DeleteOrphanedDeployments'
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  # This is the third time to schedule `DeleteOrphanedDeployments` migration.
  # The first time failed by an inappropriate batch size and the second time failed by a retry bug.
  # Since there is no issue in this migration itself, we can simply requeue the
  # migration jobs **without** no-op-ing the previous migration.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69051#note_669230405 for more information.
  def up
    delete_queued_jobs(MIGRATION)

    requeue_background_migration_jobs_by_range_at_intervals(MIGRATION, DELAY_INTERVAL)
  end

  def down
    # no-op
  end
end
