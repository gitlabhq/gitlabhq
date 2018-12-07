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

      private

      def knative_services
        clusters_with_knative_installed.preload_knative.map do |cluster|
          cluster.application_knative.services_for(ns: cluster.platform_kubernetes&.actual_namespace)
        end
      end

      def clusters_with_knative_installed
        @clusters.with_knative_installed
      end
    end
  end
end
