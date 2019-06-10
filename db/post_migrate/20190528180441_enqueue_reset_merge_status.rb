# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnqueueResetMergeStatus < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'ResetMergeStatus'
  DELAY_INTERVAL = 5.minutes.to_i

  disable_ddl_transaction!

  def up
    say 'Scheduling `ResetMergeStatus` jobs'

    # We currently have around 135_000 opened, mergeable MRs in GitLab.com. This iteration
    # will schedule around 13 batches of 10_000 MRs, which should take around 1 hour to
    # complete.
    relation = MergeRequest.where(state: 'opened', merge_status: 'can_be_merged')

    relation.each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * DELAY_INTERVAL, MIGRATION, range)
    end
  end
end
