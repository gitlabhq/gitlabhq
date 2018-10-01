# frozen_string_literal: true

class PopulateClusterProjectNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class ClusterProject < ActiveRecord::Base
    include EachBatch
    self.table_name = 'cluster_projects'
  end

  def up
    ClusterProject.where(namespace: nil).tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            'PopulateClusterProjectNamespace',
                                                            5.minutes,
                                                            batch_size: 500)
    end
  end

  def down
    # noop
  end
end
