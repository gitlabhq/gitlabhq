# frozen_string_literal: true

module DeploymentPlatform
  # EE would override this and utilize environment argument
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def deployment_platform(environment: nil)
    @deployment_platform ||= {}

    @deployment_platform[environment] ||= find_deployment_platform(environment)
  end

  # EE would override this and utilize environment argument
  def deployment_cluster(environment: nil)
    deployment_platform(environment: environment)&.cluster
  end

  private

  def find_deployment_platform(environment)
    find_cluster(environment: environment)&.platform_kubernetes ||
      find_kubernetes_service_integration ||
      build_cluster&.platform_kubernetes
  end

  # EE would override this and utilize environment argument
  def find_cluster(environment: nil)
    clusters.enabled.default_environment.last
  end

  def find_kubernetes_service_integration
    services.deployment.reorder(nil).find_by(active: true)
  end

  def build_cluster
    return unless kubernetes_service_template

    cluster = ::Clusters::Cluster.create(cluster_attributes_from_service_template)
    cluster if cluster.persisted?
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
