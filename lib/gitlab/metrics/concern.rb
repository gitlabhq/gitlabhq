module Gitlab
  module Metrics
    module Concern
      extend ActiveSupport::Concern

      included do
        @@_metrics_provider_mutex ||= Mutex.new
        @@_metrics_provider_cache ||= {}
      end

      class_methods do
        def reload_metric!(name)
          @@_metrics_provider_cache.delete(name)
        end

        private

        def define_metric(type, name, opts = {}, &block)
          if instance_methods(false).include?(name)
            raise ArgumentError, "metrics method #{name} already exists"
          end

          define_singleton_method(name) do
            # avoid unnecessary method call to speed up metric access
            return @@_metrics_provider_cache[name] if @@_metrics_provider_cache.has_key?(name)

            fetch_metric(type, name, opts, &block)
          end
        end

        def fetch_metric(type, name, opts = {}, &block)
          # avoid synchronization to speed up metrics access
          return @@_metrics_provider_cache[name] if @@_metrics_provider_cache.has_key?(name)

          options = MetricOptions.new(opts)
          options.evaluate(&block)

          @@_metrics_provider_mutex.synchronize do
            @@_metrics_provider_cache[name] ||= build_metric!(type, name, options)
          end

          @@_metrics_provider_cache[name]
        end

        def build_metric!(type, name, options)
          unless options.with_feature.nil? || Feature.get(options.with_feature).enabled?
            return NullMetric.new
          end

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
          define_metric(:counter, name, opts, &block)
        end

        # DFetch and/or initialize gauge metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_gauge(name, opts = {}, &block)
          define_metric(:counter, name, opts, &block)
        end

        # Fetch and/or initialize histogram metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_histogram(name, opts = {}, &block)
          define_metric(:histogram, name, opts, &block)
        end

        # Fetch and/or initialize summary metric
        # @param [Symbol] name
        # @param [Hash] opts
        def fetch_summary(name, opts = {}, &block)
          define_metric(:summary, name, opts, &block)
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
          define_metric(:counter, name, opts, &block)
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
