# frozen_string_literal: true
module Clusters
  class KnativeServicesFinder
    include ReactiveCaching
    include Gitlab::Utils::StrongMemoize

    KNATIVE_STATES = {
      'checking' => 'checking',
      'installed' => 'installed',
      'not_found' => 'not_found'
    }.freeze

    self.reactive_cache_key = ->(finder) { finder.model_name }
    self.reactive_cache_work_type = :external_dependency
    self.reactive_cache_worker_finder = ->(_id, *cache_args) { from_cache(*cache_args) }

    attr_reader :cluster, :environment

    def self.from_cache(cluster_id, environment_id)
      cluster = Clusters::Cluster.find(cluster_id)
      environment = Environment.find(environment_id)

      new(cluster, environment)
    end

    def initialize(cluster, environment)
      @cluster = cluster
      @environment = environment
    end

    def with_reactive_cache_memoized(*cache_args, &block)
      strong_memoize(:reactive_cache) do
        with_reactive_cache(*cache_args, &block)
      end
    end

    def clear_cache!
      clear_reactive_cache!(*cache_args)
    end

    def calculate_reactive_cache(*)
      # read_services calls knative_client.discover implicitily. If we stop
      # detecting services but still want to detect knative, we'll need to
      # explicitily call: knative_client.discover
      #
      # We didn't create it separately to avoid 2 cluster requests.
      ksvc = read_services
      pods = knative_client.discovered ? read_pods : []
      { services: ksvc, pods: pods, knative_detected: knative_client.discovered }
    end

    def services
      return [] unless search_namespace

      cached_data = with_reactive_cache_memoized(*cache_args) { |data| data }
      cached_data.to_h.fetch(:services, [])
    end

    def cache_args
      [cluster.id, environment.id]
    end

    def service_pod_details(service)
      cached_data = with_reactive_cache_memoized(*cache_args) { |data| data }
      cached_data.to_h.fetch(:pods, []).select do |pod|
        filter_pods(pod, service)
      end
    end

    def knative_detected
      cached_data = with_reactive_cache_memoized(*cache_args) { |data| data }

      knative_state = cached_data.to_h[:knative_detected]

      return KNATIVE_STATES['checking'] if knative_state.nil?
      return KNATIVE_STATES['installed'] if knative_state

      KNATIVE_STATES['uninstalled']
    end

    def model_name
      self.class.name.underscore.tr('/', '_')
    end

    private

    def search_namespace
      @search_namespace ||= cluster.kubernetes_namespace_for(environment)
    end

    def knative_client
      cluster.kubeclient.knative_client
    end

    def filter_pods(pod, service)
      pod["metadata"]["labels"]["serving.knative.dev/service"] == service
    end

    def read_services
      knative_client.get_services(namespace: search_namespace).as_json
    rescue Kubeclient::ResourceNotFoundError
      []
    end

    def read_pods
      cluster.kubeclient.core_client.get_pods(namespace: search_namespace).as_json
    end

    def id
      nil
    end
  end
end
