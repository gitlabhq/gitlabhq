# frozen_string_literal: true

class ScheduleDeleteOrphanedDeployments < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'DeleteOrphanedDeployments'
  BATCH_SIZE = 100_000
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    # no-op.
    # This background migration is rescheduled in 20210722010101_cleanup_delete_orphaned_deployments_background_migration.rb
    # with a smaller batch size, because the initial attempt caused
    # 80 failures out of 1639 batches (faiulre rate is 4.88%) due to statement timeouts,
    # that takes approx. 1 hour to perform a cleanup/sync migration.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/335071#note_618380503 for more information.
  end

  def down
    # no-op
  end
end
