# frozen_string_literal: true

module Clusters
  class Project < ActiveRecord::Base
    include Gitlab::Utils::StrongMemoize

    self.table_name = 'cluster_projects'

    belongs_to :cluster, class_name: 'Clusters::Cluster'
    belongs_to :project, class_name: '::Project'

    has_many :kubernetes_namespaces, class_name: 'Clusters::KubernetesNamespace', foreign_key: :cluster_project_id
    has_one :last_kubernetes_namespace, -> { order created_at: :desc }, class_name: 'Clusters::KubernetesNamespace', foreign_key: :cluster_project_id

    alias_method :kubernetes_namespace, :last_kubernetes_namespace
  end
end
