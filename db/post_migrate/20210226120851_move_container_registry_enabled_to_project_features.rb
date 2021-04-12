# frozen_string_literal: true

class MoveContainerRegistryEnabledToProjectFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 50_000
  MIGRATION = 'MoveContainerRegistryEnabledToProjectFeature'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch
    self.table_name = 'projects'
  end

  def up
    # no-op
    # Superceded by db/post_migrate/20210401131948_move_container_registry_enabled_to_project_features2.rb

    # queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, 2.minutes, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
