module PrometheusAdapter
  extend ActiveSupport::Concern

  included do
    include ReactiveCaching

    self.reactive_cache_key = ->(adapter) { [adapter.class.model_name.singular, adapter.id] }
    self.reactive_cache_lease_timeout = 30.seconds
    self.reactive_cache_refresh_interval = 30.seconds
    self.reactive_cache_lifetime = 1.minute

    def prometheus_client
      raise NotImplementedError
    end

    def prometheus_client_wrapper
      Gitlab::PrometheusClient.new(prometheus_client)
    end

    def can_query?
      prometheus_client.present?
    end

    def query(query_name, *args)
      return unless can_query?

      query_class = Gitlab::Prometheus::Queries.const_get("#{query_name.to_s.classify}Query")

      args.map!(&:id)

      with_reactive_cache(query_class.name, *args, &query_class.method(:transform_reactive_result))
    end

    # Cache metrics for specific environment
    def calculate_reactive_cache(query_class_name, *args)
      return unless prometheus_client

      data = Kernel.const_get(query_class_name).new(prometheus_client_wrapper).query(*args)
      {
        success: true,
        data: data,
        last_update: Time.now.utc
      }
    rescue Gitlab::PrometheusClient::Error => err
      { success: false, result: err.message }
    end
  end
end
