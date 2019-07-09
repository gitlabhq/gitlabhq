# frozen_string_literal: true

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
      application = deployment_platform&.cluster&.application_prometheus

      application if application&.available?
    end
  end
end
