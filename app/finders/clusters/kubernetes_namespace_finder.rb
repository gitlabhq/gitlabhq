# frozen_string_literal: true

module Clusters
  class KubernetesNamespaceFinder
    attr_reader :cluster, :project, :environment_name

    def initialize(cluster, project:, environment_name:, allow_blank_token: false)
      @cluster = cluster
      @project = project
      @environment_name = environment_name
      @allow_blank_token = allow_blank_token
    end

    def execute
      find_namespace(with_environment: cluster.namespace_per_environment?)
    end

    private

    attr_reader :allow_blank_token

    def find_namespace(with_environment:)
      relation = if with_environment
                   namespaces.with_environment_name(environment_name)
                 else
                   namespaces
                 end

      relation.find_by_project_id(project.id)
    end

    def namespaces
      if allow_blank_token
        cluster.kubernetes_namespaces
      else
        cluster.kubernetes_namespaces.has_service_account_token
      end
    end
  end
end
