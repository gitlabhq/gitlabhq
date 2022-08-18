# frozen_string_literal: true

module Gitlab
  module Metrics
    module Methods
      class MetricOptions
        def initialize(options = {})
          @multiprocess_mode = options[:multiprocess_mode] || :all
          @buckets = options[:buckets] || ::Prometheus::Client::Histogram::DEFAULT_BUCKETS
          @docstring = options[:docstring]
          @with_feature = options[:with_feature]
          @label_keys = options[:label_keys] || []
        end

        # Documentation describing metric in metrics endpoint '/-/metrics'
        def docstring(docstring = nil)
          @docstring = docstring unless docstring.nil?

          @docstring
        end

        # Gauge aggregation mode for multiprocess metrics
        # - :all (default) returns each gauge for every process
        # - :livesum all process'es gauges summed up
        # - :max maximum value of per process gauges
        # - :min minimum value of per process gauges
        def multiprocess_mode(mode = nil)
          @multiprocess_mode = mode unless mode.nil?

          @multiprocess_mode
        end

        # Measurement buckets for histograms
        def buckets(buckets = nil)
          @buckets = buckets unless buckets.nil?

          @buckets
        end

        # Base labels are merged with per metric labels
        def base_labels
          @base_labels ||= @label_keys.product([nil]).to_h

          @base_labels
        end

        def label_keys(label_keys = nil)
          unless label_keys.nil?
            @label_keys = label_keys
            @base_labels = nil
          end

          @label_keys
        end

        # Use feature toggle to control whether certain metric is enabled/disabled
        def with_feature(name = nil)
          @with_feature = name unless name.nil?

          @with_feature
        end

        def evaluate(&block)
          instance_eval(&block) if block

          self
        end
      end
    end
  end
end
