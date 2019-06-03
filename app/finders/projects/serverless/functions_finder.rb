# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsFinder
      attr_reader :project

      def initialize(project)
        @clusters = project.clusters
        @project = project
      end

      def execute
        knative_services.flatten.compact
      end

      # Possible return values: Clusters::KnativeServicesFinder::KNATIVE_STATE
      def knative_installed
        states = @clusters.map do |cluster|
          cluster.application_knative
          cluster.knative_services_finder(project).knative_detected.tap do |state|
            return state if state == ::Clusters::KnativeServicesFinder::KNATIVE_STATES['checking'] # rubocop:disable Cop/AvoidReturnFromBlocks
          end
        end

        states.any? { |state| state == ::Clusters::KnativeServicesFinder::KNATIVE_STATES['installed'] }
      end

      def service(environment_scope, name)
        knative_service(environment_scope, name)&.first
      end

      def invocation_metrics(environment_scope, name)
        return unless prometheus_adapter&.can_query?

        cluster = @clusters.find do |c|
          environment_scope == c.environment_scope
        end

        func = ::Serverless::Function.new(project, name, cluster.kubernetes_namespace_for(project))
        prometheus_adapter.query(:knative_invocation, func)
      end

      def has_prometheus?(environment_scope)
        @clusters.any? do |cluster|
          environment_scope == cluster.environment_scope && cluster.application_prometheus_available?
        end
      end

      private

      def knative_service(environment_scope, name)
        @clusters.map do |cluster|
          next if environment_scope != cluster.environment_scope

          services = cluster
            .knative_services_finder(project)
            .services
            .select { |svc| svc["metadata"]["name"] == name }

          add_metadata(cluster, services).first unless services.nil?
        end
      end

      def knative_services
        @clusters.map do |cluster|
          services = cluster
            .knative_services_finder(project)
            .services

          add_metadata(cluster, services) unless services.nil?
        end
      end

      def add_metadata(cluster, services)
        services.each do |s|
          s["environment_scope"] = cluster.environment_scope
          s["cluster_id"] = cluster.id

          if services.length == 1
            s["podcount"] = cluster
              .knative_services_finder(project)
              .service_pod_details(s["metadata"]["name"])
              .length
          end
        end
      end

      # rubocop: disable CodeReuse/ServiceClass
      def prometheus_adapter
        @prometheus_adapter ||= ::Prometheus::AdapterService.new(project).prometheus_adapter
      end
      # rubocop: enable CodeReuse/ServiceClass
    end
  end
end
