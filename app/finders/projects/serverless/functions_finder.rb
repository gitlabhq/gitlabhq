# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsFinder
      def initialize(clusters)
        @clusters = clusters
      end

      def execute
        knative_services.flatten.compact
      end

      def installed?
        clusters_with_knative_installed.exists?
      end

      def service(environment_scope, name)
        knative_service(environment_scope, name)&.first
      end

      private

      def knative_service(environment_scope, name)
        clusters_with_knative_installed.preload_knative.map do |cluster|
          next if environment_scope != cluster.environment_scope

          services = cluster.application_knative.services_for(ns: cluster.platform_kubernetes&.actual_namespace)
            .select { |svc| svc["metadata"]["name"] == name }

          add_metadata(cluster, services).first unless services.nil?
        end
      end

      def knative_services
        clusters_with_knative_installed.preload_knative.map do |cluster|
          services = cluster.application_knative.services_for(ns: cluster.platform_kubernetes&.actual_namespace)
          add_metadata(cluster, services) unless services.nil?
        end
      end

      def add_metadata(cluster, services)
        services.each do |s|
          s["environment_scope"] = cluster.environment_scope
          s["cluster_id"] = cluster.id

          if services.length == 1
            s["podcount"] = cluster.application_knative.service_pod_details(
              cluster.platform_kubernetes&.actual_namespace,
              s["metadata"]["name"]).length
          end
        end
      end

      def clusters_with_knative_installed
        @clusters.with_knative_installed
      end
    end
  end
end
