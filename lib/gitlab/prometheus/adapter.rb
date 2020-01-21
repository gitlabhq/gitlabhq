# frozen_string_literal: true

module Gitlab
  module Prometheus
    class Adapter
      attr_reader :project, :cluster

      def initialize(project, cluster)
        @project = project
        @cluster = cluster
      end

      def prometheus_adapter
        @prometheus_adapter ||= if service_prometheus_adapter.can_query?
                                  service_prometheus_adapter
                                else
                                  cluster_prometheus_adapter
                                end
      end

      def cluster_prometheus_adapter
        application = cluster&.application_prometheus

        application if application&.available?
      end

      private

      def service_prometheus_adapter
        project.find_or_initialize_service('prometheus')
      end
    end
  end
end
