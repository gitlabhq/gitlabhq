module Gitlab
  module Metrics
    module Concern
      class MetricOptions
        def initialize(options = {})
          @multiprocess_mode = options[:multiprocess_mode] || :all
          @buckets = options[:buckets] || ::Prometheus::Client::Histogram::DEFAULT_BUCKETS
          @base_labels = options[:base_labels] || {}
        end

        def docs(docs = nil)
          @docs = docs unless docs.nil?

          @docs
        end

        def multiprocess_mode(mode)
          @multiprocess_mode = mode unless @multiprocess_mode.nil?

          @multiprocess_mode
        end

        def buckets(buckets)
          @buckets = buckets unless @buckets.nil?

          @buckets
        end

        def base_labels(base_labels)
          @base_labels = base_labels unless @base_labels.nil?

          @base_labels
        end

        def with_feature(name)
          @feature_name = name unless @feature_name.nil?

          @feature_name
        end

        def evaluate(&block)
          instance_eval(&block) if block_given?
          self
        end
      end
    end
  end
end
