# frozen_string_literal: true

class ScheduleExtractProjectTopicsIntoSeparateTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  DELAY_INTERVAL = 2.minutes
  MIGRATION = 'ExtractProjectTopicsIntoSeparateTable'
  INDEX_NAME = 'tmp_index_taggings_on_id_where_taggable_type_project'
  INDEX_CONDITION = "taggable_type = 'Project'"

  disable_ddl_transaction!

  class Tagging < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'taggings'
  end

  def up
    # this index is used in 20210730104800_schedule_extract_project_topics_into_separate_table
    add_concurrent_index :taggings, :id, where: INDEX_CONDITION, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation

    queue_background_migration_jobs_by_range_at_intervals(
      Tagging.where(taggable_type: 'Project'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    remove_concurrent_index_by_name :taggings, INDEX_NAME
  end
end
