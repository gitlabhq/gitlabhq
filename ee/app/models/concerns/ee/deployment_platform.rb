module EE
  module DeploymentPlatform
    extend ::Gitlab::Utils::Override

    override :find_cluster_platform_kubernetes
    def find_cluster_platform_kubernetes(environment: nil)
      return super unless environment && feature_available?(:multiple_clusters)

      clusters.enabled
        .on_environment(environment)
        .last&.platform_kubernetes
    end
  end
end
