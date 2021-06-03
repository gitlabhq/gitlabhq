# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsFinder
      include Gitlab::Utils::StrongMemoize
      include ReactiveCaching

      attr_reader :project

      self.reactive_cache_key = ->(finder) { finder.cache_key }
      self.reactive_cache_work_type = :external_dependency
      self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

      MAX_CLUSTERS = 10

      def initialize(project)
        @project = project
      end

      def execute
        knative_services.flatten.compact
      end

      def knative_installed
        return knative_installed_from_cluster?(*cache_key) if available_environments.empty?

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
          finder.cluster.integration_prometheus_available?
        end
      end

      def self.from_cache(project_id)
        project = Project.find(project_id)

        new(project)
      end

      def cache_key(*args)
        [project.id]
      end

      def calculate_reactive_cache(*)
        # rubocop: disable CodeReuse/ActiveRecord
        project.all_clusters.enabled.take(MAX_CLUSTERS).any? do |cluster|
          cluster.kubeclient.knative_client.discover
        rescue Kubeclient::ResourceNotFoundError
          next
        end
      end

      private

      def knative_installed_from_cluster?(*cache_key)
        cached_data = with_reactive_cache_memoized(*cache_key) { |data| data }

        return ::Clusters::KnativeServicesFinder::KNATIVE_STATES['checking'] if cached_data.nil?

        cached_data ? true : false
      end

      def with_reactive_cache_memoized(*cache_key)
        strong_memoize(:reactive_cache) do
          with_reactive_cache(*cache_key) { |data| data }
        end
      end

      def knative_service(environment_scope, name)
        finders_for_scope(environment_scope).map do |finder|
          services = finder
            .services
            .select { |svc| svc["metadata"]["name"] == name }

          attributes = add_metadata(finder, services).first
          next unless attributes

          Gitlab::Serverless::Service.new(attributes)
        end
      end

      def knative_services
        services_finders.map do |finder|
          attributes = add_metadata(finder, finder.services)

          attributes&.map do |attributes|
            Gitlab::Serverless::Service.new(attributes)
          end
        end
      end

      def add_metadata(finder, services)
        return if services.nil?

        add_pod_count = services.one?

        services.each do |s|
          s["environment_scope"] = finder.cluster.environment_scope
          s["environment"] = finder.environment
          s["cluster"] = finder.cluster

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

      def id
        nil
      end
    end
  end
end
