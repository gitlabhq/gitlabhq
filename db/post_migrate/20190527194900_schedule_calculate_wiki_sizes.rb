# frozen_string_literal: true

class ScheduleCalculateWikiSizes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'CalculateWikiSizes'
  BATCH_SIZE = 100000
  BATCH_TIME = 5.minutes

  class ProjectStatistics < ActiveRecord::Base
    self.table_name = 'project_statistics'

    scope :without_wiki_size, -> { where(wiki_size: nil) }

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      ::ScheduleCalculateWikiSizes::ProjectStatistics.without_wiki_size,
      MIGRATION,
      BATCH_TIME,
      batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
