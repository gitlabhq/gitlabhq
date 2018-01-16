module Gitlab
  module Metrics
    module Concern
      class MetricOptions
        def initialize(options = {})
          @multiprocess_mode = options[:multiprocess_mode] || :all
          @buckets = options[:buckets] || ::Prometheus::Client::Histogram::DEFAULT_BUCKETS
          @base_labels = options[:base_labels] || {}
          @docstring = options[:docstring]
          @with_feature = options[:with_feature]
        end

        def docstring(docstring = nil)
          @docstring = docstring unless docstring.nil?

          @docstring
        end

        def multiprocess_mode(mode = nil)
          @multiprocess_mode = mode unless mode.nil?

          @multiprocess_mode
        end

        def buckets(buckets = nil)
          @buckets = buckets unless buckets.nil?

          @buckets
        end

        def base_labels(base_labels = nil)
          @base_labels = base_labels unless base_labels.nil?

          @base_labels
        end

        def with_feature(name = nil)
          @feature_name = name unless name.nil?

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
