# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleProjectAnyApprovalRuleMigration < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5_000
  MIGRATION = 'PopulateAnyApprovalRuleForProjects'
  DELAY_INTERVAL = 8.minutes.to_i

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'

    scope :with_approvals_before_merge, -> { where('approvals_before_merge <> 0') }
  end

  def up
    return unless Gitlab.ee?

    add_concurrent_index :projects, :id,
      name: 'tmp_projects_with_approvals_before_merge',
      where: 'approvals_before_merge <> 0'

    say "Scheduling `#{MIGRATION}` jobs"

    # We currently have ~43k project records with non-zero approvals_before_merge on GitLab.com.
    # This means it'll schedule ~9 jobs (5k projects each) with a 8 minutes gap,
    # so this should take ~1 hour for all background migrations to complete.
    #
    # The approximate expected number of affected rows is: 18k

    queue_background_migration_jobs_by_range_at_intervals(
      ScheduleProjectAnyApprovalRuleMigration::Project.with_approvals_before_merge,
      MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)

    remove_concurrent_index_by_name(:projects, 'tmp_projects_with_approvals_before_merge')
  end

  def down
    # no-op
  end
end
