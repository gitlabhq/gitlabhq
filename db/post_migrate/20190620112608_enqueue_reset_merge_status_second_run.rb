# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnqueueResetMergeStatusSecondRun < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'ResetMergeStatus'
  DELAY_INTERVAL = 5.minutes.to_i

  disable_ddl_transaction!

  def up
    say 'Scheduling `ResetMergeStatus` jobs'

    # We currently have more than ~5_000_000 merge request records on GitLab.com.
    # This means it'll schedule ~500 jobs (10k MRs each) with a 5 minutes gap,
    # so this should take ~41 hours for all background migrations to complete.
    # ((5_000_000 / 10_000) * 5) / 60 => 41.6666..
    queue_background_migration_jobs_by_range_at_intervals(MergeRequest, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end
end
