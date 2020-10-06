# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleEpicIssuesAfterEpicsMove < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 5.minutes.to_i
  BATCH_SIZE = 100
  MIGRATION = 'MoveEpicIssuesAfterEpics'

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'

    include ::EachBatch
  end

  def up
    return unless ::Gitlab.ee?

    Epic.each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(id)', 'MAX(id)').first
      delay = index * INTERVAL
      BackgroundMigrationWorker.perform_in(delay, MIGRATION, range)
    end
  end

  def down
    # no need
  end
end
