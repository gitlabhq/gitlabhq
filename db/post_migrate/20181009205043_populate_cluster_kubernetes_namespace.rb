# frozen_string_literal: true

class PopulateClusterKubernetesNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class ClusterProject < ActiveRecord::Base
    include EachBatch
    self.table_name = 'cluster_projects'
  end

  class ClusterKubernetesNamespace < ActiveRecord::Base
    self.table_name = 'clusters_kubernetes_namespaces'
  end

  def up
    cluster_project_with_no_namespace = ClusterProject.where.not(id: ClusterKubernetesNamespace.select(:id))

    cluster_project_with_no_namespace.tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            'PopulateClusterKubernetesNamespace',
                                                            5.minutes,
                                                            batch_size: 500)
    end
  end

  def down
    # noop
  end
end
