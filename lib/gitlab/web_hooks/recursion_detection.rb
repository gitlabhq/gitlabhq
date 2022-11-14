# frozen_string_literal: true

# This module detects and blocks recursive webhook requests.
#
# Recursion can happen when a webhook has been configured to make a call
# to its own GitLab instance (i.e., its API), and during the execution of
# the call the webhook is triggered again to create an infinite loop of
# being triggered.
#
# Additionally the module blocks a webhook once the number of requests to
# the instance made by a series of webhooks triggering other webhooks reaches
# a limit.
#
# Blocking recursive webhooks allows GitLab to continue to support workflows
# that use webhooks to call the API non-recursively, or do not go on to
# trigger an unreasonable number of other webhooks.
module Gitlab
  module WebHooks
    module RecursionDetection
      COUNT_LIMIT = 100
      TOUCH_CACHE_TTL = 30.minutes

      class << self
        def set_from_headers(headers)
          uuid = headers[UUID::HEADER]

          return unless uuid

          set_request_uuid(uuid)
        end

        def set_request_uuid(uuid)
          UUID.instance.request_uuid = uuid
        end

        # Before a webhook is executed, `.register!` should be called.
        # Adds the webhook ID to a cache (see `#cache_key_for_hook` for
        # details of the cache).
        def register!(hook)
          cache_key = cache_key_for_hook(hook)

          ::Gitlab::Redis::SharedState.with do |redis|
            redis.multi do |multi|
              multi.sadd?(cache_key, hook.id)
              multi.expire(cache_key, TOUCH_CACHE_TTL)
            end
          end
        end

        # Returns true if the webhook ID is present in the cache, or if the
        # number of IDs in the cache exceeds the limit (see
        # `#cache_key_for_hook` for details of the cache).
        def block?(hook)
          # If a request UUID has not been set then we know the request was not
          # made by a webhook, and no recursion is possible.
          return false unless UUID.instance.request_uuid

          cache_key = cache_key_for_hook(hook)

          ::Gitlab::Redis::SharedState.with do |redis|
            redis.sismember(cache_key, hook.id) ||
              redis.scard(cache_key) >= COUNT_LIMIT
          end
        end

        def header(hook)
          UUID.instance.header(hook)
        end

        def to_log(hook)
          {
            uuid: UUID.instance.uuid_for_hook(hook),
            ids: ::Gitlab::Redis::SharedState.with { |redis| redis.smembers(cache_key_for_hook(hook)).map(&:to_i) }
          }
        end

        private

        # Returns a cache key scoped to a UUID.
        #
        # The particular UUID will be either:
        #
        #   - A UUID that was recycled from the request headers if the request was made by a webhook.
        #   - a new UUID initialized for the webhook.
        #
        # This means that cycles of webhooks that are triggered from other webhooks
        # will share the same cache, and other webhooks will use a new cache.
        def cache_key_for_hook(hook)
          [:webhook_recursion_detection, UUID.instance.uuid_for_hook(hook)].join(':')
        end
      end
    end
  end
end
