module Gitlab
  module Metrics
    module Concern
      extend ActiveSupport::Concern
      MUTEX = Mutex.new

      class_methods do
        def reload_metric!(name)
          @_metrics_provider_cache&.delete(name)
        end

        private

        def define_metric(type, name, opts = {}, &block)
          if respond_to?(name)
            raise ArgumentError, "metrics method #{name} already exists"
          end

          define_singleton_method(name) do
            # avoid unnecessary method call to speed up metric access
            metric = @_metrics_provider_cache&.[](name)
            return metric if metric

            fetch_metric(type, name, opts, &block)
          end
        end

        def fetch_metric(type, name, opts = {}, &block)
          # avoid synchronization to speed up metrics access
          metric = @_metrics_provider_cache&.[](name)
          return metric if metric

          options = MetricOptions.new(opts)
          options.evaluate(&block)

          MUTEX.synchronize do
            @_metrics_provider_cache ||= {}
            @_metrics_provider_cache[name] ||= build_metric!(type, name, options)
          end

          @_metrics_provider_cache[name]
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
          fetch_metric(:counter, name, opts, &block)
        end

        # DFetch and/or initialize gauge metric
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
