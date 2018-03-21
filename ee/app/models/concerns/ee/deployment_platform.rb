module EE
  module DeploymentPlatform
    extend ::Gitlab::Utils::Override

    override :deployment_platform
    def deployment_platform(environment: nil)
      find_cluster_platform_kubernetes(environment: environment) ||
        find_kubernetes_service_integration ||
        build_cluster_and_deployment_platform
    end

    private

    override :find_cluster_platform_kubernetes
    def find_cluster_platform_kubernetes(environment: nil)
      return super unless environment && feature_available?(:multiple_clusters)

      clusters.enabled.on_environment(environment.name)
        .last&.platform_kubernetes
    end
  end
end
