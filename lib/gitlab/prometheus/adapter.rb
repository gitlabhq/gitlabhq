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
        @prometheus_adapter ||= find_cluster_prometheus_adapter
      end

      def find_cluster_prometheus_adapter
        integration = cluster&.integration_prometheus
        integration if integration&.available?
      end
    end
  end
end
