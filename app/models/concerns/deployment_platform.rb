# frozen_string_literal: true

module DeploymentPlatform
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def deployment_platform(environment: nil)
    @deployment_platform ||= {}

    @deployment_platform[environment] ||= find_deployment_platform(environment)
  end

  private

  def find_deployment_platform(environment)
    find_platform_kubernetes_with_cte(environment) ||
      find_instance_cluster_platform_kubernetes(environment: environment)
  end

  def find_platform_kubernetes_with_cte(environment)
    if environment
      ::Clusters::ClustersHierarchy.new(self)
        .base_and_ancestors
        .enabled
        .on_environment(environment, relevant_only: true)
        .first&.platform_kubernetes
    else
      Clusters::ClustersHierarchy.new(self).base_and_ancestors
      .enabled.default_environment
      .first&.platform_kubernetes
    end
  end

  def find_instance_cluster_platform_kubernetes(environment: nil)
    if environment
      ::Clusters::Instance.new.clusters.enabled.on_environment(environment, relevant_only: true)
      .first&.platform_kubernetes
    else
      Clusters::Instance.new.clusters.enabled.default_environment
      .first&.platform_kubernetes
    end
  end
end
