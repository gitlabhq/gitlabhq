# frozen_string_literal: true

module Clusters
  class BuildKubernetesNamespaceService
    attr_reader :cluster, :environment

    def initialize(cluster, environment:)
      @cluster = cluster
      @environment = environment
    end

    def execute
      cluster.kubernetes_namespaces.build(attributes)
    end

    private

    def attributes
      attributes = {
        project: environment.project,
        namespace: namespace,
        service_account_name: "#{namespace}-service-account"
      }

      attributes[:cluster_project] = cluster.cluster_project if cluster.project_type?
      attributes[:environment] = environment if cluster.namespace_per_environment?

      attributes
    end

    def namespace
      Gitlab::Kubernetes::DefaultNamespace.new(cluster, project: environment.project).from_environment_slug(environment.slug)
    end
  end
end
