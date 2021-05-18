# frozen_string_literal: true

class ScheduleMigrateProjectTaggingsContextFromTagsToTopics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 30_000
  DELAY_INTERVAL = 2.minutes
  MIGRATION = 'MigrateProjectTaggingsContextFromTagsToTopics'

  disable_ddl_transaction!

  class Tagging < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'taggings'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Tagging.where(taggable_type: 'Project', context: 'tags'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
  end
end
