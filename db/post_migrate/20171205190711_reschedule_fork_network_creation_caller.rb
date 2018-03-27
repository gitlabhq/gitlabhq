class RescheduleForkNetworkCreationCaller < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'PopulateForkNetworksRange'.freeze
  BATCH_SIZE = 100
  DELAY_INTERVAL = 15.seconds

  disable_ddl_transaction!

  class ForkedProjectLink < ActiveRecord::Base
    include EachBatch

    self.table_name = 'forked_project_links'
  end

  def up
    say 'Populating the `fork_networks` based on existing `forked_project_links`'

    queue_background_migration_jobs_by_range_at_intervals(ForkedProjectLink, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # nothing
  end
end
