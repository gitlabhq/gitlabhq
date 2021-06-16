# frozen_string_literal: true

module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      include Gitlab::Metrics::Methods

      # base label keys shared among all transactions
      BASE_LABEL_KEYS = %i(controller action feature_category).freeze
      # labels that potentially contain sensitive information and will be filtered
      FILTERED_LABEL_KEYS = %i(branch path).freeze

      THREAD_KEY = :_gitlab_metrics_transaction

      # The series to store events (e.g. Git pushes) in.
      EVENT_SERIES = 'events'

      attr_reader :method

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
            label_keys BASE_LABEL_KEYS | (label_keys - FILTERED_LABEL_KEYS)
          end
        end
      end

      def initialize
        @methods = {}
      end

      def run
        raise NotImplementedError
      end

      # Tracks a business level event
      #
      # Business level events including events such as Git pushes, Emails being
      # sent, etc.
      #
      # event_name - The name of the event (e.g. "git_push").
      # tags - A set of tags to attach to the event.
      def add_event(event_name, tags = {})
        event_name = "gitlab_transaction_event_#{event_name}_total".to_sym
        metric = self.class.prometheus_metric(event_name, :counter) do
          label_keys tags.keys
        end

        metric.increment(filter_labels(tags))
      end

      # Returns a MethodCall object for the given name.
      def method_call_for(name, module_name, method_name)
        unless method = @methods[name]
          @methods[name] = method = MethodCall.new(name, module_name, method_name, self)
        end

        method
      end

      # Increment counter metric
      #
      # It will initialize the metric if metric is not found
      #
      # block - if provided can be used to initialize metric with custom options (docstring, labels, with_feature)
      #
      # Example:
      # ```
      # transaction.increment(:mestric_name, 1, { docstring: 'Custom title', base_labels: {sane: 'yes'} } ) do
      #
      # transaction.increment(:mestric_name, 1) do
      #   docstring 'Custom title'
      #   label_keys %i(sane)
      # end
      # ```
      def increment(name, value = 1, labels = {}, &block)
        counter = self.class.prometheus_metric(name, :counter, &block)

        counter.increment(filter_labels(labels), value)
      end

      # Set gauge metric
      #
      # It will initialize the metric if metric is not found
      #
      # block - if provided, it can be used to initialize metric with custom options (docstring, labels, with_feature, multiprocess_mode)
      # - multiprocess_mode is :all by default
      #
      # Example:
      # ```
      # transaction.set(:mestric_name, 1) do
      #   multiprocess_mode :livesum
      # end
      # ```
      def set(name, value, labels = {}, &block)
        gauge = self.class.prometheus_metric(name, :gauge, &block)

        gauge.set(filter_labels(labels), value)
      end

      # Observe histogram metric
      #
      # It will initialize the metric if metric is not found
      #
      # block - if provided, it can be used to initialize metric with custom options (docstring, labels, with_feature, buckets)
      #
      # Example:
      # ```
      # transaction.observe(:mestric_name, 1) do
      #   buckets [100, 1000, 10000, 100000, 1000000, 10000000]
      # end
      # ```
      def observe(name, value, labels = {}, &block)
        histogram = self.class.prometheus_metric(name, :histogram, &block)

        histogram.observe(filter_labels(labels), value)
      end

      def labels
        BASE_LABEL_KEYS.product([nil]).to_h
      end

      def filter_labels(labels)
        labels.empty? ? self.labels : labels.without(*FILTERED_LABEL_KEYS).merge(self.labels)
      end
    end
  end
end
