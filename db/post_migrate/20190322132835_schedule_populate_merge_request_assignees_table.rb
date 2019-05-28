# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SchedulePopulateMergeRequestAssigneesTable < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'PopulateMergeRequestAssigneesTable'
  DELAY_INTERVAL = 8.minutes.to_i

  disable_ddl_transaction!

  def up
    say 'Scheduling `PopulateMergeRequestAssigneesTable` jobs'
    # We currently have ~4_500_000 merge request records on GitLab.com.
    # This means it'll schedule ~450 jobs (10k MRs each) with a 8 minutes gap,
    # so this should take ~60 hours for all background migrations to complete.
    queue_background_migration_jobs_by_range_at_intervals(MergeRequest, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end
end
