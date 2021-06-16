# frozen_string_literal: true

module PrometheusAdapter
  extend ActiveSupport::Concern

  # We should choose more conservative timeouts, but some queries we run are now busting our
  # default timeouts, which are stricter. We should make those queries faster instead.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/232786
  DEFAULT_PROMETHEUS_REQUEST_TIMEOUT_SEC = 60.seconds

  included do
    include ReactiveCaching

    self.reactive_cache_lease_timeout = 30.seconds
    self.reactive_cache_refresh_interval = 30.seconds
    self.reactive_cache_lifetime = 1.minute
    self.reactive_cache_work_type = :external_dependency

    def prometheus_client
      raise NotImplementedError
    end

    def prometheus_client_default_options
      {
        timeout: DEFAULT_PROMETHEUS_REQUEST_TIMEOUT_SEC
      }
    end

    # Overridden in app/models/clusters/applications/prometheus.rb
    def managed_prometheus?
      false
    end

    # This is a light-weight check if a prometheus client is properly configured.
    def configured?
      raise NotImplementedError
    end

    # This is a heavy-weight check if a prometheus is properly configured and accessible from GitLab.
    # This actually sends a request to an external service and often it could take a long time,
    # Please consider using `configured?` instead if the process is running on Puma threads.
    def can_query?
      prometheus_client.present?
    end

    def query(query_name, *args)
      return unless can_query?

      query_class = query_klass_for(query_name)
      query_args = build_query_args(*args)

      with_reactive_cache(query_class.name, *query_args, &query_class.method(:transform_reactive_result))
    end

    # Cache metrics for specific environment
    def calculate_reactive_cache(query_class_name, *args)
      return unless prometheus_client

      data = Object.const_get(query_class_name, false).new(prometheus_client).query(*args)
      {
        success: true,
        data: data,
        last_update: Time.current.utc
      }
    rescue Gitlab::PrometheusClient::Error => err
      { success: false, result: err.message }
    end

    def query_klass_for(query_name)
      Gitlab::Prometheus::Queries.const_get("#{query_name.to_s.classify}Query", false)
    end

    def build_query_args(*args)
      args.map { |arg| arg.respond_to?(:id) ? arg.id : arg }
    end

    def clear_prometheus_reactive_cache!(query_name, *args)
      query_class = query_klass_for(query_name)
      query_args = build_query_args(*args)

      clear_reactive_cache!(query_class.name, *query_args)
    end
  end
end
