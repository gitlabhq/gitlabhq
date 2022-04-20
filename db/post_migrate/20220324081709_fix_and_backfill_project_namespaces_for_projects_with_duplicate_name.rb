# frozen_string_literal: true

class FixAndBackfillProjectNamespacesForProjectsWithDuplicateName < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'FixDuplicateProjectNameAndPath'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000

  class Project < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'projects'

    scope :without_project_namespace, -> { where(project_namespace_id: nil) }
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Project.without_project_namespace, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE, track_jobs: true
    )
  end

  def down
    # no-op
  end
end
