# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total time spent in Rails cache calls
      # http://guides.rubyonrails.org/active_support_instrumentation.html
      class RailsCache < ActiveSupport::Subscriber
        attach_to :active_support

        def cache_read(event)
          observe(:read, event.duration)

          return unless current_transaction
          return if event.payload[:super_operation] == :fetch

          unless event.payload[:hit]
            current_transaction.increment(:gitlab_cache_misses_total, 1) do
              docstring 'Cache read miss'
            end
          end
        end

        def cache_write(event)
          observe(:write, event.duration)
        end

        def cache_delete(event)
          observe(:delete, event.duration)
        end

        def cache_exist?(event)
          observe(:exists, event.duration)
        end

        def cache_fetch_hit(event)
          return unless current_transaction

          current_transaction.increment(:gitlab_transaction_cache_read_hit_count_total, 1)
        end

        def cache_generate(event)
          return unless current_transaction

          current_transaction.increment(:gitlab_cache_misses_total, 1) do
            docstring 'Cache read miss'
          end

          current_transaction.increment(:gitlab_transaction_cache_read_miss_count_total, 1)
        end

        def observe(key, duration)
          return unless current_transaction

          labels = { operation: key }

          current_transaction.increment(:gitlab_cache_operations_total, 1, labels) do
            docstring 'Cache operations'
            label_keys labels.keys
          end

          metric_cache_operation_duration_seconds.observe(labels, duration / 1000.0)
        end

        private

        def current_transaction
          Transaction.current
        end

        def metric_cache_operation_duration_seconds
          @metric_cache_operation_duration_seconds ||= ::Gitlab::Metrics.histogram(
            :gitlab_cache_operation_duration_seconds,
            'Cache access time',
            {},
            [0.00001, 0.0001, 0.001, 0.01, 0.1, 1.0]
          )
        end
      end
    end
  end
end
