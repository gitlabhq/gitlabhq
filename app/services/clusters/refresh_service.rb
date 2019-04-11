# frozen_string_literal: true

module Clusters
  class RefreshService
    def self.create_or_update_namespaces_for_cluster(cluster)
      projects_with_missing_kubernetes_namespaces_for_cluster(cluster).each do |project|
        create_or_update_namespace(cluster, project)
      end
    end

    def self.create_or_update_namespaces_for_project(project)
      clusters_with_missing_kubernetes_namespaces_for_project(project).each do |cluster|
        create_or_update_namespace(cluster, project)
      end
    end

    def self.projects_with_missing_kubernetes_namespaces_for_cluster(cluster)
      cluster.all_projects.missing_kubernetes_namespace(cluster.kubernetes_namespaces)
    end

    private_class_method :projects_with_missing_kubernetes_namespaces_for_cluster

    def self.clusters_with_missing_kubernetes_namespaces_for_project(project)
      project.clusters.managed.missing_kubernetes_namespace(project.kubernetes_namespaces)
    end

    private_class_method :clusters_with_missing_kubernetes_namespaces_for_project

    def self.create_or_update_namespace(cluster, project)
      kubernetes_namespace = cluster.find_or_initialize_kubernetes_namespace_for_project(project)

      ::Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService.new(
        cluster: cluster,
        kubernetes_namespace: kubernetes_namespace
      ).execute
    end

    private_class_method :create_or_update_namespace
  end
end
