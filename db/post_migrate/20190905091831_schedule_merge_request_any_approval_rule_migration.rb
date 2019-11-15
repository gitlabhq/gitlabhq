# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleMergeRequestAnyApprovalRuleMigration < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5_000
  MIGRATION = 'PopulateAnyApprovalRuleForMergeRequests'
  DELAY_INTERVAL = 8.minutes.to_i

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    scope :with_approvals_before_merge, -> { where('approvals_before_merge <> 0') }
  end

  def up
    return unless Gitlab.ee?

    add_concurrent_index :merge_requests, :id,
      name: 'tmp_merge_requests_with_approvals_before_merge',
      where: 'approvals_before_merge <> 0'

    say "Scheduling `#{MIGRATION}` jobs"

    # We currently have ~440_000 merge request records with non-zero approvals_before_merge on GitLab.com.
    # This means it'll schedule ~88 jobs (5k merge requests each) with a 8 minutes gap,
    # so this should take ~12 hours for all background migrations to complete.
    #
    # The approximate expected number of affected rows is: 190k

    queue_background_migration_jobs_by_range_at_intervals(
      ScheduleMergeRequestAnyApprovalRuleMigration::MergeRequest.with_approvals_before_merge,
      MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)

    remove_concurrent_index_by_name(:merge_requests, 'tmp_merge_requests_with_approvals_before_merge')
  end

  def down
    # no-op
  end
end
