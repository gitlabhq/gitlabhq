module Gitlab
  module Metrics
    module Concern
      extend ActiveSupport::Concern
      class_methods do
        private

        def metrics_provider(type, name, docstring, options = {})
          @@_metrics_provider_mutex ||= Mutex.new

          if instance_methods(false).include?(name)
            raise ArgumentError, "metrics class method #{name} already exists"
          end
          options[:base_labels] ||= {}

          args = [name.inspect, %{"#{docstring}"}, options[:base_labels].inspect]

          case type
            when :gauge
              options[:multiprocess_mode] ||= :all
              args << options[:multiprocess_mode].inspect
            when :histogram
              options[:buckets] ||= ::Prometheus::Client::Histogram::DEFAULT_BUCKETS
              args << options[:buckets].inspect
          end

          metric_fetching_code = %{Gitlab::Metrics::Prometheus.#{type}(#{args.join(', ')})}

          # optionally wrap in feature
          metric_fetching_code = if options[:with_feature].is_a?(Symbol)
                                   <<-FETCH.strip_heredoc
                                  if Feature.get(#{options[:with_feature].inspect}).enabled? 
                                    #{metric_fetching_code}
                                  else
                                    Gitlab::Metrics::NullMetric.new
                                  end
                                   FETCH
                                 end

          method_code, line = <<-METRIC, __LINE__ + 1
            def #{name}
              @@_metric_provider_cached_#{name} if @@_metric_provider_cached_#{name}

              @@_metrics_provider_mutex.synchronize do
                @_metric_provider_cached_#{name} ||= #{metric_fetching_code}
              end
            end
          METRIC

          class_eval(method_code, __FILE__, line)
          module_eval(method_code, __FILE__, line)
        end

        # Declare a Counter
        # @param [Symbol] name
        # @param [String] docstring
        # @param [Hash] opts
        def counter(name, docstring, opts = {})
          metrics_provider(:counter, name, docstring, options)
        end

        # Declare a Gauge
        # @param [Symbol] name
        # @param [String] docstring
        # @param [Hash] opts
        def gauge(name, docstring, opts = {})
          metrics_provider(:counter, name, docstring, opts)
        end

        # Declare a Histograam
        # @param [Symbol] name
        # @param [String] docstring
        # @param [Hash] opts
        def histogram(name, docstring, opts = {})
          metrics_provider(:histogram, name, docstring, opts)
        end

        def summary(*args)
          raise NotImplementedError, "summary metrics are not currently supported"
        end
      end
    end
  end
end
