module DeploymentPlatform
  # EE would override this and utilize environment argument
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def deployment_platform(environment: nil)
    ensure_kubernetes_cluster_template

    @deployment_platform ||= {}

    @deployment_platform[environment] ||= find_deployment_platform(environment)
  end

  # We create KubernetesService object to indicate that it was imported from active template
  # Saved KubernetesService object ensures that corresponding Cluster is created
  # KubernetesService itself is shallow holder of parameters only
  def ensure_kubernetes_cluster_template
    return if kubernetes_service
    return unless kubernetes_service_template

    Service.build_from_template(id, kubernetes_service_template).save!
  end

  private

  def find_deployment_platform(environment)
    find_cluster_platform_kubernetes(environment: environment)
  end

  # EE would override this and utilize environment argument
  def find_cluster_platform_kubernetes(environment: nil)
    clusters.enabled.default_environment
      .last&.platform_kubernetes
  end

  def kubernetes_service_template
    @kubernetes_service_template ||= KubernetesService.active.find_by_template
  end
end
