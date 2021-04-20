# frozen_string_literal: true

module Gitlab
  module Metrics
    class BackgroundTransaction < Transaction
      # Separate web transaction instance and background transaction instance
      BACKGROUND_THREAD_KEY = :_gitlab_metrics_background_transaction
      BACKGROUND_BASE_LABEL_KEYS = %i(endpoint_id feature_category).freeze

      class << self
        def current
          Thread.current[BACKGROUND_THREAD_KEY]
        end

        def prometheus_metric(name, type, &block)
          fetch_metric(type, name) do
            # set default metric options
            docstring "#{name.to_s.humanize} #{type}"

            evaluate(&block)
            # always filter sensitive labels and merge with base ones
            label_keys BACKGROUND_BASE_LABEL_KEYS | (label_keys - ::Gitlab::Metrics::Transaction::FILTERED_LABEL_KEYS)
          end
        end
      end

      def run
        Thread.current[BACKGROUND_THREAD_KEY] = self

        yield
      ensure
        Thread.current[BACKGROUND_THREAD_KEY] = nil
      end

      def labels
        @labels ||= {
          endpoint_id: endpoint_id,
          feature_category: feature_category,
          queue: queue
        }
      end

      private

      def current_context
        Labkit::Context.current
      end

      def feature_category
        current_context&.get_attribute(:feature_category)
      end

      def endpoint_id
        current_context&.get_attribute(:caller_id)
      end

      def queue
        worker_class = endpoint_id.to_s.safe_constantize
        return if worker_class.blank? || !worker_class.respond_to?(:queue)

        worker_class.queue.to_s
      end
    end
  end
end
