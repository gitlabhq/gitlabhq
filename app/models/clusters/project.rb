# frozen_string_literal: true

module Clusters
  class Project < ActiveRecord::Base
    self.table_name = 'cluster_projects'

    belongs_to :cluster, class_name: 'Clusters::Cluster'
    belongs_to :project, class_name: '::Project'
    
    has_many :kubernetes_namespaces, class_name: 'Clusters::KubernetesNamespace', foreign_key: :cluster_project_id

    def last_kubernetes_namespace
      return @last_kubernetes_namespace if defined?(@last_kubernetes_namespace)

      @first_kubernetes_namespace = kubernetes_namespaces.last
    end
    alias_method :kubernetes_namespace, :last_kubernetes_namespace
  end
end
