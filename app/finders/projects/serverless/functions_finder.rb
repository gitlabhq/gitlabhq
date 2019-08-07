# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsFinder
      include Gitlab::Utils::StrongMemoize

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def execute
        knative_services.flatten.compact
      end

      # Possible return values: Clusters::KnativeServicesFinder::KNATIVE_STATE
      def knative_installed
        states = services_finders.map do |finder|
          finder.knative_detected.tap do |state|
            return state if state == ::Clusters::KnativeServicesFinder::KNATIVE_STATES['checking'] # rubocop:disable Cop/AvoidReturnFromBlocks
          end
        end

        states.any? { |state| state == ::Clusters::KnativeServicesFinder::KNATIVE_STATES['installed'] }
      end

      def service(environment_scope, name)
        knative_service(environment_scope, name)&.first
      end

      def invocation_metrics(environment_scope, name)
        environment = finders_for_scope(environment_scope).first&.environment

        if environment.present? && environment.prometheus_adapter&.can_query?
          func = ::Serverless::Function.new(project, name, environment.deployment_namespace)
          environment.prometheus_adapter.query(:knative_invocation, func)
        end
      end

      def has_prometheus?(environment_scope)
        finders_for_scope(environment_scope).any? do |finder|
          finder.cluster.application_prometheus_available?
        end
      end

      private

      def knative_service(environment_scope, name)
        finders_for_scope(environment_scope).map do |finder|
          services = finder
            .services
            .select { |svc| svc["metadata"]["name"] == name }

          add_metadata(finder, services).first unless services.nil?
        end
      end

      def knative_services
        services_finders.map do |finder|
          services = finder.services

          add_metadata(finder, services) unless services.nil?
        end
      end

      def add_metadata(finder, services)
        add_pod_count = services.one?

        services.each do |s|
          s["environment_scope"] = finder.cluster.environment_scope
          s["cluster_id"] = finder.cluster.id

          if add_pod_count
            s["podcount"] = finder
              .service_pod_details(s["metadata"]["name"])
              .length
          end
        end
      end

      def services_finders
        strong_memoize(:services_finders) do
          available_environments.map(&:knative_services_finder).compact
        end
      end

      def available_environments
        @project.environments.available.preload_cluster
      end

      def finders_for_scope(environment_scope)
        services_finders.select do |finder|
          environment_scope == finder.cluster.environment_scope
        end
      end
    end
  end
end
