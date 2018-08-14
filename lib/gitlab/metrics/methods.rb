# rubocop:disable Style/ClassVars

module Gitlab
  module Metrics
    module Methods
      extend ActiveSupport::Concern

      included do
        @@_metric_provider_mutex ||= Mutex.new
        @@_metrics_provider_cache = {}
      end

      class_methods do
        def reload_metric!(name)
          @@_metrics_provider_cache.delete(name)
        end

        private

        def define_metric(type, name, opts = {}, &block)
          if respond_to?(name)
            raise ArgumentError, "method #{name} already exists"
          end

          define_singleton_method(name) do
            # inlining fetch_metric method to avoid method call overhead when instrumenting hot spots
            @@_metrics_provider_cache[name] || init_metric(type, name, opts, &block)
          end
        end

        def fetch_metric(type, name, opts = {}, &block)
          @@_metrics_provider_cache[name] || init_metric(type, name, opts, &block)
        end

        def init_metric(type, name, opts = {}, &block)
          options = MetricOptions.new(opts)
          options.evaluate(&block)

          if disabled_by_feature(options)
            synchronized_cache_fill(name) { NullMetric.instance }
          else
            synchronized_cache_fill(name) { build_metric!(type, name, options) }
          end
        end

        def synchronized_cache_fill(key)
          @@_metric_provider_mutex.synchronize do
            @@_metrics_provider_cache[key] ||= yield
          end
        end

        def disabled_by_feature(options)
          options.with_feature && !::Feature.get(options.with_feature).enabled?
        end

        def build_metric!(type, name, options)
          case type
          when :gauge
            Gitlab::Metrics.gauge(name, options.docstring, options.base_labels, options.multiprocess_mode)
          when :counter
            Gitlab::Metrics.counter(name, options.docstring, options.base_labels)
          when :histogram
            Gitlab::Metrics.histogram(name, options.docstring, options.base_labels, options.buckets)
          when :summary
            raise NotImplementedError, "summary metrics are not currently supported"
          else
            raise ArgumentError, "uknown metric type #{type}"
          end
        end

        # Fetch and/or initialize counter metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_counter(name, opts = {}, &block)
          fetch_metric(:counter, name, opts, &block)
        end

        # Fetch and/or initialize gauge metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_gauge(name, opts = {}, &block)
          fetch_metric(:gauge, name, opts, &block)
        end

        # Fetch and/or initialize histogram metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_histogram(name, opts = {}, &block)
          fetch_metric(:histogram, name, opts, &block)
        end

        # Fetch and/or initialize summary metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_summary(name, opts = {}, &block)
          fetch_metric(:summary, name, opts, &block)
        end

        # Define metric accessor method for a Counter
        # @param [Symbol] name
        # @param [Hash] opts
        def define_counter(name, opts = {}, &block)
          define_metric(:counter, name, opts, &block)
        end

        # Define metric accessor method for a Gauge
        # @param [Symbol] name
        # @param [Hash] opts
        def define_gauge(name, opts = {}, &block)
          define_metric(:gauge, name, opts, &block)
        end

        # Define metric accessor method for a Histogram
        # @param [Symbol] name
        # @param [Hash] opts
        def define_histogram(name, opts = {}, &block)
          define_metric(:histogram, name, opts, &block)
        end

        # Define metric accessor method for a Summary
        # @param [Symbol] name
        # @param [Hash] opts
        def define_summary(name, opts = {}, &block)
          define_metric(:summary, name, opts, &block)
        end
      end
    end
  end
end
