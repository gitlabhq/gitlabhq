# frozen_string_literal: true

# Proxies calls to a Grafana-integrated Prometheus instance
# through the Grafana proxy API

# This allows us to fetch and render metrics in GitLab from a Prometheus
# instance for which dashboards are configured in Grafana
module Grafana
  class ProxyService < BaseService
    include ReactiveCaching

    self.reactive_cache_key = ->(service) { service.cache_key }
    self.reactive_cache_lease_timeout = 30.seconds
    self.reactive_cache_refresh_interval = 30.seconds
    self.reactive_cache_work_type = :external_dependency
    self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

    attr_accessor :project, :datasource_id, :proxy_path, :query_params

    # @param project_id [Integer] Project id for which grafana is configured.
    #
    # See #initialize for other parameters.
    def self.from_cache(project_id, datasource_id, proxy_path, query_params)
      project = Project.find(project_id)

      new(project, datasource_id, proxy_path, query_params)
    end

    # @param project [Project] Project for which grafana is configured.
    # @param datasource_id [String] Grafana datasource id for Prometheus instance
    # @param proxy_path [String] Path to Prometheus endpoint; EX) 'api/v1/query_range'
    # @param query_params [Hash<String, String>] Supported params: [query, start, end, step]
    def initialize(project, datasource_id, proxy_path, query_params)
      @project = project
      @datasource_id = datasource_id
      @proxy_path = proxy_path
      @query_params = query_params
    end

    def execute
      return cannot_proxy_response unless client

      with_reactive_cache(*cache_key) { |result| result }
    end

    def calculate_reactive_cache(*)
      return cannot_proxy_response unless client

      response = client.proxy_datasource(
        datasource_id: datasource_id,
        proxy_path: proxy_path,
        query: query_params
      )

      success(http_status: response.code, body: response.body)
    rescue ::Grafana::Client::Error => error
      service_unavailable_response(error)
    end

    # Required for ReactiveCaching; Usage overridden by
    # self.reactive_cache_worker_finder
    def id
      nil
    end

    def cache_key
      [project.id, datasource_id, proxy_path, query_params]
    end

    private

    def client
      project.grafana_integration&.client
    end

    def service_unavailable_response(exception)
      error(exception.message, :service_unavailable)
    end

    def cannot_proxy_response
      error('Proxy support for this API is not available currently')
    end
  end
end
