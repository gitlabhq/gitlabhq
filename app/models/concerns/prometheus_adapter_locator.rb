module PrometheusAdapterLocator
  def deployment_platform
    project.deployment_platform
  end

  def prometheus_adapter
    @prometheus_adapter ||= if service_prometheus_adapter.can_query?
                              service_prometheus_adapter
                            else
                              cluster_prometheus_adapter
                            end
  end

  def service_prometheus_adapter
    project.find_or_initialize_service('prometheus')
  end

  def cluster_prometheus_adapter
    return unless deployment_platform.respond_to?(:cluster)

    cluster = deployment_platform.cluster
    return unless cluster.application_prometheus&.installed?

    cluster.application_prometheus
  end
end