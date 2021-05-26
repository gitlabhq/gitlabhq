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

  # Disabling this old migration because it should already run
  # in 14.0. This will allow us to remove some `technical debt`
  # in ProjectStatistics model, because of some columns
  # not present by the time the migration is run.
  def up
    # no-op
  end

  def down
    # no-op
  end
end
