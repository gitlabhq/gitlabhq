module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total time spent in Rails cache calls
      # http://guides.rubyonrails.org/active_support_instrumentation.html
      class RailsCache < ActiveSupport::Subscriber
        attach_to :active_support

        def self.metric_cache_duration_seconds
          @metric_cache_duration_seconds ||= Gitlab::Metrics.histogram(
            :gitlab_cache_duration_seconds,
            'Cache access time',
            { action: nil, operation: nil },
            [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]
          )
        end

        def self.metric_cache_read_hit_total
          @metric_cache_read_hit_total ||= Gitlab::Metrics.counter(:gitlab_cache_read_hit_total, 'Cache read hit', { action: nil })
        end

        def self.metric_cache_read_miss_total
          @metric_cache_read_miss_total ||= Gitlab::Metrics.counter(:gitlab_cache_read_miss_total, 'Cache read miss', { action: nil })
        end

        def cache_read(event)
          observe(:read, event.duration)

          return unless current_transaction
          return if event.payload[:super_operation] == :fetch

          if event.payload[:hit]
            self.class.metric_cache_read_hit_total.increment({ action: action })
            current_transaction.increment(:cache_read_hit_count, 1)
          else
            self.class.metric_cache_read_miss_total.increment({ action: action })
            current_transaction.increment(:cache_read_miss_count, 1)
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

          self.class.metric_cache_read_hit_total.increment({ action: action })
          current_transaction.increment(:cache_read_hit_count, 1)
        end

        def cache_generate(event)
          return unless current_transaction

          self.class.metric_cache_read_miss_total.increment({ action: action })
          current_transaction.increment(:cache_read_miss_count, 1)
        end

        def observe(key, duration)
          return unless current_transaction

          metric_cache_duration_seconds.observe({ operation: key, action: action }, duration / 1000.1)
          current_transaction.increment(:cache_duration, duration, false)
          current_transaction.increment(:cache_count, 1, false)
          current_transaction.increment("#{key}_duration".to_sym, duration, false)
          current_transaction.increment("#{key}_count".to_sym, 1, false)
        end

        private

        def action
          current_transaction&.action
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
