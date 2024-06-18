# frozen_string_literal: true

module Gitlab
  module Metrics
    # Exclusive transaction-type metrics for web servers (including Web/Api/Git
    # fleet). One instance of this class is created for each request going
    # through the Rack metric middleware. Any metrics dispatched with this
    # instance include metadata such as controller, action, feature category,
    # etc.
    class WebTransaction < Transaction
      THREAD_KEY = :_gitlab_metrics_transaction
      BASE_LABEL_KEYS = %i[controller action feature_category endpoint_id].freeze

      CONTROLLER_KEY = 'action_controller.instance'
      ENDPOINT_KEY = 'api.endpoint'
      ALLOWED_SUFFIXES = Set.new(%w[json js atom rss xml zip])
      SMALL_BUCKETS = [0.1, 0.25, 0.5, 1.0, 2.5, 5.0].freeze

      class << self
        def current
          Thread.current[THREAD_KEY]
        end

        def prometheus_metric(name, type, &block)
          fetch_metric(type, name) do
            # set default metric options
            docstring "#{name.to_s.humanize} #{type}"

            evaluate(&block)
            # always filter sensitive labels and merge with base ones
            label_keys BASE_LABEL_KEYS | (label_keys - ::Gitlab::Metrics::Transaction::FILTERED_LABEL_KEYS)
          end
        end
      end

      def initialize(env)
        super()
        @env = env
      end

      def run
        Thread.current[THREAD_KEY] = self

        started_at = System.monotonic_time

        status, _, _ = retval = yield

        finished_at = System.monotonic_time
        duration = finished_at - started_at
        record_duration_if_needed(status, duration)

        retval
      ensure
        Thread.current[THREAD_KEY] = nil
      end

      def labels
        return @labels if @labels

        # memoize transaction labels only source env variables were present
        @labels = if @env[CONTROLLER_KEY]
                    labels_from_controller || {}
                  elsif @env[ENDPOINT_KEY]
                    labels_from_endpoint || {}
                  end

        @labels || {}
      end

      private

      def record_duration_if_needed(status, duration)
        return unless Gitlab::Metrics.record_duration_for_status?(status)

        observe(:gitlab_transaction_duration_seconds, duration) do
          buckets SMALL_BUCKETS
        end
      end

      def labels_from_controller
        controller = @env[CONTROLLER_KEY]

        action = controller.action_name.to_s

        # Devise exposes a method called "request_format" that does the below.
        # However, this method is not available to all controllers (e.g. certain
        # Doorkeeper controllers). As such we use the underlying code directly.
        suffix = controller.request.format.try(:ref).to_s

        # Sometimes the request format is set to silly data such as
        # "application/xrds+xml" or actual URLs. To prevent such values from
        # increasing the cardinality of our metrics, we limit the number of
        # possible suffixes.
        if suffix && ALLOWED_SUFFIXES.include?(suffix)
          action = "#{action}.#{suffix}"
        end

        {
          controller: controller.class.name,
          action: action,
          feature_category: feature_category,
          # inline endpoint_id_for_action as not all controllers extend ApplicationController
          endpoint_id: "#{controller.class.name}##{controller.action_name}"
        }
      end

      def labels_from_endpoint
        endpoint = @env[ENDPOINT_KEY]

        begin
          route = endpoint.route
        rescue StandardError
          # endpoint.route is calling env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
          # but env[Grape::Env::GRAPE_ROUTING_ARGS] is nil in the case of a 405 response
          # so we're rescuing exceptions and bailing out
        end

        if route
          path = endpoint_paths_cache[route.request_method][route.path]

          {
            controller: 'Grape',
            action: "#{route.request_method} #{path}",
            feature_category: feature_category,
            endpoint_id: API::Base.endpoint_id_for_route(route)
          }
        end
      end

      def endpoint_paths_cache
        @endpoint_paths_cache ||= Hash.new do |hash, http_method|
          hash[http_method] = Hash.new do |inner_hash, raw_path|
            inner_hash[raw_path] = endpoint_instrumentable_path(raw_path)
          end
        end
      end

      def endpoint_instrumentable_path(raw_path)
        raw_path.sub('(.:format)', '').sub('/:version', '')
      end

      def feature_category
        ::Gitlab::ApplicationContext.current_context_attribute(:feature_category) || ::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT
      end
    end
  end
end
