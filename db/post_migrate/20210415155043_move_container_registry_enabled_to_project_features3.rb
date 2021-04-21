# frozen_string_literal: true

class MoveContainerRegistryEnabledToProjectFeatures3 < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::DynamicModelHelpers

  BATCH_SIZE = 21_000
  MIGRATION = 'MoveContainerRegistryEnabledToProjectFeature'

  disable_ddl_transaction!

  def up
    # Delete any existing jobs from the queue
    delete_queued_jobs(MIGRATION)

    # Delete existing rows in background_migration_jobs table
    bg_migration_job_class = define_model('background_migration_jobs')
    bg_migration_job_class.where(class_name: MIGRATION).delete_all

    batchable_project_class = define_batchable_model('projects')
    queue_background_migration_jobs_by_range_at_intervals(batchable_project_class, MIGRATION, 2.minutes, batch_size: BATCH_SIZE, track_jobs: true)
  end

  def down
    # no-op
  end

  private

  def define_model(table_name)
    Class.new(ActiveRecord::Base) do
      self.table_name = table_name
      self.inheritance_column = :_type_disabled
    end
  end
end
