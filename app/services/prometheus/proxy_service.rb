# frozen_string_literal: true

module Prometheus
  class ProxyService < BaseService
    include ReactiveCaching

    self.reactive_cache_key = ->(service) { service.cache_key }
    self.reactive_cache_lease_timeout = 30.seconds
    self.reactive_cache_refresh_interval = 30.seconds
    self.reactive_cache_lifetime = 1.minute
    self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

    attr_accessor :prometheus_owner, :method, :path, :params

    PROXY_SUPPORT = {
      'query' => 'GET',
      'query_range' => 'GET'
    }.freeze

    def self.from_cache(prometheus_owner_class_name, prometheus_owner_id, method, path, params)
      prometheus_owner_class = begin
        prometheus_owner_class_name.constantize
      rescue NameError
        nil
      end
      return unless prometheus_owner_class

      prometheus_owner = prometheus_owner_class.find(prometheus_owner_id)

      new(prometheus_owner, method, path, params)
    end

    # prometheus_owner can be any model which responds to .prometheus_adapter
    # like Environment.
    def initialize(prometheus_owner, method, path, params)
      @prometheus_owner = prometheus_owner
      @path = path
      # Convert ActionController::Parameters to hash because reactive_cache_worker
      # does not play nice with ActionController::Parameters.
      @params = params.to_hash
      @method = method
    end

    def id
      nil
    end

    def execute
      return cannot_proxy_response unless can_proxy?(@method, @path)
      return no_prometheus_response unless can_query?

      with_reactive_cache(*cache_key) do |result|
        result
      end
    end

    def calculate_reactive_cache(prometheus_owner_class_name, prometheus_owner_id, method, path, params)
      @prometheus_owner = prometheus_owner_from_class(prometheus_owner_class_name, prometheus_owner_id)

      return cannot_proxy_response unless can_proxy?(method, path)
      return no_prometheus_response unless can_query?

      response = prometheus_client_wrapper.proxy(path, params)

      success({ http_status: response.code, body: response.body })

    rescue Gitlab::PrometheusClient::Error => err
      error(err.message, :service_unavailable)
    end

    def cache_key
      [@prometheus_owner.class.name, @prometheus_owner.id, @method, @path, @params]
    end

    private

    def no_prometheus_response
      error('No prometheus server found', :service_unavailable)
    end

    def cannot_proxy_response
      error('Proxy support for this API is not available currently')
    end

    def prometheus_owner_from_class(prometheus_owner_class_name, prometheus_owner_id)
      Kernel.const_get(prometheus_owner_class_name).find(prometheus_owner_id)
    end

    def prometheus_adapter
      @prometheus_adapter ||= @prometheus_owner.prometheus_adapter
    end

    def prometheus_client_wrapper
      prometheus_adapter&.prometheus_client_wrapper
    end

    def can_query?
      prometheus_adapter&.can_query?
    end

    def can_proxy?(method, path)
      PROXY_SUPPORT[path] == method
    end
  end
end
