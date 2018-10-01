# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class CacheInvalidationEvent
          include BaseEvent

          def process
            result = expire_cache_for_event_key
            log_cache_invalidation_event(result)
          end

          private

          def expire_cache_for_event_key
            Rails.cache.delete(event.key)
          end

          def log_cache_invalidation_event(expired)
            logger.event_info(
              created_at,
              'Cache invalidation',
              cache_key: event.key,
              cache_expired: expired,
              skippable: skippable?
            )
          end

          def skippable?
            false
          end
        end
      end
    end
  end
end
