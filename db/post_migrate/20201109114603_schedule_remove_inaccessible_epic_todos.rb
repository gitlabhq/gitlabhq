# frozen_string_literal: true

class ScheduleRemoveInaccessibleEpicTodos < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes
  BATCH_SIZE = 10
  MIGRATION = 'RemoveInaccessibleEpicTodos'

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    include EachBatch
  end

  def up
    return unless Gitlab.ee?

    relation = Epic.where(confidential: true)

    queue_background_migration_jobs_by_range_at_intervals(
      relation, MIGRATION, INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
