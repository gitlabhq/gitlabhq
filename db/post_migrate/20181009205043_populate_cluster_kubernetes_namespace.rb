# frozen_string_literal: true

class PopulateClusterKubernetesNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'PopulateClusterKubernetesNamespace'.freeze

  disable_ddl_transaction!

  class ClusterProject < ActiveRecord::Base
    self.table_name = 'cluster_projects'
    include EachBatch

    BATCH_SIZE = 500

    def self.params_for_background_migration
      yield all, MIGRATION, 5.minutes, BATCH_SIZE
    end
  end

  def up
    ClusterProject.params_for_background_migration do |relation, class_name, delay_interval, batch_size|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            class_name,
                                                            delay_interval,
                                                            batch_size: batch_size)
    end
  end

  def down
    # noop
  end
end
