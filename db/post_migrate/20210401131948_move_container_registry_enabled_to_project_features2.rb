# frozen_string_literal: true

class MoveContainerRegistryEnabledToProjectFeatures2 < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 21_000
  MIGRATION = 'MoveContainerRegistryEnabledToProjectFeature'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch
    self.table_name = 'projects'
  end

  def up
    # Superceded by db/post_migrate/20210415155043_move_container_registry_enabled_to_project_features3.rb.

    # delete_queued_jobs('MoveContainerRegistryEnabledToProjectFeature')

    # queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, 2.minutes, batch_size: BATCH_SIZE, track_jobs: true)
  end

  def down
    # no-op
  end
end
