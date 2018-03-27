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

          if event.payload[:hit]
            current_transaction.increment(:cache_read_hit_count, 1, false)
          else
            metric_cache_misses_total.increment(current_transaction.labels)
            current_transaction.increment(:cache_read_miss_count, 1, false)
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

          current_transaction.increment(:cache_read_hit_count, 1)
        end

        def cache_generate(event)
          return unless current_transaction

          metric_cache_misses_total.increment(current_transaction.labels)
          current_transaction.increment(:cache_read_miss_count, 1)
        end

        def observe(key, duration)
          return unless current_transaction

          metric_cache_operation_duration_seconds.observe(current_transaction.labels.merge({ operation: key }), duration / 1000.0)
          current_transaction.increment(:cache_duration, duration, false)
          current_transaction.increment(:cache_count, 1, false)
          current_transaction.increment("cache_#{key}_duration".to_sym, duration, false)
          current_transaction.increment("cache_#{key}_count".to_sym, 1, false)
        end

        private

        def current_transaction
          Transaction.current
        end

        def metric_cache_operation_duration_seconds
          @metric_cache_operation_duration_seconds ||= Gitlab::Metrics.histogram(
            :gitlab_cache_operation_duration_seconds,
            'Cache access time',
            Transaction::BASE_LABELS.merge({ action: nil }),
            [0.001, 0.01, 0.1, 1, 10]
          )
        end

        def metric_cache_misses_total
          @metric_cache_misses_total ||= Gitlab::Metrics.counter(
            :gitlab_cache_misses_total,
            'Cache read miss',
            Transaction::BASE_LABELS
          )
        end
      end
    end
  end
end
