module DeploymentPlatform
  # EE would override this and utilize environment argument
  def deployment_platform(environment: nil)
    @deployment_platform ||=
      find_cluster_platform_kubernetes(environment: environment) ||
      find_kubernetes_service_integration ||
      build_cluster_and_deployment_platform
  end

  private

  # EE would override this and utilize environment argument
  def find_cluster_platform_kubernetes(environment: nil)
    clusters.enabled.default_environment
      .last&.platform_kubernetes
  end

  def find_kubernetes_service_integration
    services.deployment.reorder(nil).find_by(active: true)
  end

  def build_cluster_and_deployment_platform
    return unless kubernetes_service_template

    cluster = ::Clusters::Cluster.create(cluster_attributes_from_service_template)
    cluster.platform_kubernetes if cluster.persisted?
  end

  def kubernetes_service_template
    @kubernetes_service_template ||= KubernetesService.active.find_by_template
  end

  def cluster_attributes_from_service_template
    {
      name: 'kubernetes-template',
      projects: [self],
      provider_type: :user,
      platform_type: :kubernetes,
      platform_kubernetes_attributes: platform_kubernetes_attributes_from_service_template
    }
  end

  def platform_kubernetes_attributes_from_service_template
    {
      api_url: kubernetes_service_template.api_url,
      ca_pem: kubernetes_service_template.ca_pem,
      token: kubernetes_service_template.token,
      namespace: kubernetes_service_template.namespace
    }
  end
end
