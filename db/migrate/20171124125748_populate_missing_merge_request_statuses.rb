# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateMissingMergeRequestStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
  end

  def up
    say 'Populating missing merge_requests.state values'

    # GitLab.com has no rows where "state" is NULL, and technically this should
    # never happen. However it doesn't hurt to be 100% certain.
    MergeRequest.where(state: nil).each_batch do |batch|
      batch.update_all(state: 'opened')
    end

    say 'Populating missing merge_requests.merge_status values. ' \
      'This will take a few minutes...'

    # GitLab.com has 66 880 rows where "merge_status" is NULL, dating back all
    # the way to 2011.
    MergeRequest.where(merge_status: nil).each_batch(of: 10_000) do |batch|
      batch.update_all(merge_status: 'unchecked')

      # We want to give PostgreSQL some time to vacuum any dead tuples. In
      # production we see it takes roughly 1 minute for a vacuuming run to clear
      # out 10-20k dead tuples, so we'll wait for 90 seconds between every
      # batch.
      sleep(90) if sleep?
    end
  end

  def down
    # Reverting this makes no sense.
  end

  def sleep?
    Rails.env.staging? || Rails.env.production?
  end
end
