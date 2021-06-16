# frozen_string_literal: true

class CleanupMoveContainerRegistryEnabledToProjectFeature < ActiveRecord::Migration[6.0]
  MIGRATION = 'MoveContainerRegistryEnabledToProjectFeature'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION)

    bg_migration_job_class = define_background_migration_jobs_class
    bg_migration_job_class.where(class_name: MIGRATION, status: bg_migration_job_class.statuses['pending']).each do |job|
      Gitlab::BackgroundMigration::MoveContainerRegistryEnabledToProjectFeature.new.perform(*job.arguments)
    end

    bg_migration_job_class.where(class_name: MIGRATION).delete_all
  end

  def down
    # no-op
  end

  private

  def define_background_migration_jobs_class
    Class.new(ActiveRecord::Base) do
      self.table_name = 'background_migration_jobs'
      self.inheritance_column = :_type_disabled

      enum status: {
        pending: 0,
        succeeded: 1
      }
    end
  end
end
