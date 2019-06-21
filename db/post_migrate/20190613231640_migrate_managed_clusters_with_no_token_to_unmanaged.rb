# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateManagedClustersWithNoTokenToUnmanaged < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Cluster < ActiveRecord::Base
    include EachBatch

    self.table_name = 'clusters'

    has_many :kubernetes_namespaces, class_name: 'MigrateManagedClustersWithNoTokenToUnmanaged::KubernetesNamespace'

    scope :managed, -> { where(managed: true) }

    enum cluster_type: {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }
  end

  class KubernetesNamespace < ActiveRecord::Base
    self.table_name = 'clusters_kubernetes_namespaces'

    belongs_to :cluster, class_name: 'MigrateManagedClustersWithNoTokenToUnmanaged::Cluster'
  end

  def up
    Cluster.managed
      .project_type
      .joins(:kubernetes_namespaces)
      .where(clusters_kubernetes_namespaces: { encrypted_service_account_token: nil })
      .where('clusters.created_at < ?', Date.new(2018, 12, 1).midnight)
      .each_batch do |batch|
        batch.update_all(managed: false)
      end
  end

  def down
  end
end
