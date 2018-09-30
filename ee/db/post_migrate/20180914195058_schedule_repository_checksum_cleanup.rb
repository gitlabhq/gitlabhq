# frozen_string_literal: true

class ScheduleRepositoryChecksumCleanup < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'ResetChecksumFromProjectRepositoryStates'.freeze
  BATCH_SIZE = 10_000
  DELAY_INTERVAL = 5.minutes.to_i

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch
  end

  class ProjectRepositoryState < ActiveRecord::Base
    self.table_name = 'project_repository_states'
  end

  disable_ddl_transaction!

  def up
    # This background migration should only affect EE installations,
    # which has entries in the project_repository_states table.
    return unless ProjectRepositoryState.exists?

    now = Time.now

    projects_to_cleanup =
      Project
        .where(Project.arel_table[:last_repository_updated_at].lteq(now))

    projects_to_cleanup.each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first
      delay = index * DELAY_INTERVAL

      BackgroundMigrationWorker.perform_in(delay, MIGRATION, range)
    end
  end

  def down
    # no-op
  end
end
