# frozen_string_literal: true

class ScheduleLinkLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'LinkLfsObjects'
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    fork_network_members =
      Gitlab::BackgroundMigration::LinkLfsObjects::ForkNetworkMember
        .select(1)
        .with_non_existing_lfs_objects
        .where('fork_network_members.project_id = projects.id')

    forks = Project.where('EXISTS (?)', fork_network_members)

    queue_background_migration_jobs_by_range_at_intervals(
      forks,
      MIGRATION,
      BackgroundMigrationWorker.minimum_interval,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
