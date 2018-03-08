module Prometheus
  class AdapterService
    def initialize(project, deployment_platform = nil)
      @project = project

      @deployment_platform = if deployment_platform
                               deployment_platform
                             else
                               project.deployment_platform
                             end
    end

    attr_reader :deployment_platform, :project

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
end
