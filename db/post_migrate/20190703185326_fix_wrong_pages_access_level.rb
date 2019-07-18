# frozen_string_literal: true

class FixWrongPagesAccessLevel < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'FixPagesAccessLevel'
  BATCH_SIZE = 20_000
  BATCH_TIME = 2.minutes

  disable_ddl_transaction!

  class ProjectFeature < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'project_features'
    self.inheritance_column = :_type_disabled
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      ProjectFeature,
      MIGRATION,
      BATCH_TIME,
      batch_size: BATCH_SIZE)
  end
end
