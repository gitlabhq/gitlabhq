module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total time spent in Rails cache calls
      # http://guides.rubyonrails.org/active_support_instrumentation.html
      class RailsCache < ActiveSupport::Subscriber
        attach_to :active_support

        def cache_read(event)
          increment(:cache_read, event.duration)

          return unless current_transaction
          return if event.payload[:super_operation] == :fetch

          if event.payload[:hit]
            current_transaction.increment(:cache_read_hit_count, 1)
          else
            current_transaction.increment(:cache_read_miss_count, 1)
          end
        end

        def cache_write(event)
          increment(:cache_write, event.duration)
        end

        def cache_delete(event)
          increment(:cache_delete, event.duration)
        end

        def cache_exist?(event)
          increment(:cache_exists, event.duration)
        end

        def cache_fetch_hit(event)
          return unless current_transaction

          current_transaction.increment(:cache_read_hit_count, 1)
        end

        def cache_generate(event)
          return unless current_transaction

          current_transaction.increment(:cache_read_miss_count, 1)
        end

        def increment(key, duration)
          return unless current_transaction

          current_transaction.increment(:cache_duration, duration)
          current_transaction.increment(:cache_count, 1)
          current_transaction.increment("#{key}_duration".to_sym, duration)
          current_transaction.increment("#{key}_count".to_sym, 1)
        end

        private

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
