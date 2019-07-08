# frozen_string_literal: true

class DeploymentMetrics
  include Gitlab::Utils::StrongMemoize

  attr_reader :project, :deployment

  delegate :cluster, to: :deployment

  def initialize(project, deployment)
    @project = project
    @deployment = deployment
  end

  def has_metrics?
    deployment.success? && prometheus_adapter&.can_query?
  end

  def metrics
    return {} unless has_metrics?

    metrics = prometheus_adapter.query(:deployment, deployment)
    metrics&.merge(deployment_time: deployment.finished_at.to_i) || {}
  end

  def additional_metrics
    return {} unless has_metrics?

    metrics = prometheus_adapter.query(:additional_metrics_deployment, deployment)
    metrics&.merge(deployment_time: deployment.finished_at.to_i) || {}
  end

  private

  def prometheus_adapter
    strong_memoize(:prometheus_adapter) do
      service = project.find_or_initialize_service('prometheus')

      if service.can_query?
        service
      else
        cluster_prometheus
      end
    end
  end

  # TODO remove fallback case to deployment_platform_cluster.
  # Otherwise we will continue to pay the performance penalty described in
  # https://gitlab.com/gitlab-org/gitlab-ce/issues/63475
  #
  # Removal issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/64105
  def cluster_prometheus
    cluster_with_fallback = cluster || deployment_platform_cluster

    cluster_with_fallback.application_prometheus if cluster_with_fallback&.application_prometheus_available?
  end

  def deployment_platform_cluster
    deployment.environment.deployment_platform&.cluster
  end
end
