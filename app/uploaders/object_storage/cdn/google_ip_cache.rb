# frozen_string_literal: true

module ObjectStorage
  module CDN
    class GoogleIpCache
      GOOGLE_CDN_LIST_KEY = 'google_cdn_ip_list'
      CACHE_EXPIRATION_TIME = 1.day

      class << self
        def update!(subnets)
          caches.each { |cache| cache.write(GOOGLE_CDN_LIST_KEY, subnets) }
        end

        def ready?
          caches.any? { |cache| cache.exist?(GOOGLE_CDN_LIST_KEY) }
        end

        def google_ip?(request_ip)
          google_ip_ranges = cached_value(GOOGLE_CDN_LIST_KEY)

          return false unless google_ip_ranges

          google_ip_ranges.any? { |range| range.include?(request_ip) }
        end

        def async_refresh
          ::GoogleCloud::FetchGoogleIpListWorker.perform_async
        end

        private

        def caches
          [l1_cache, l2_cache]
        end

        def l1_cache
          Gitlab::ProcessMemoryCache.cache_backend
        end

        def l2_cache
          Rails.cache
        end

        def cached_value(key)
          l1_cache.fetch(key) do
            result = l2_cache.fetch(key)

            # Don't populate the L1 cache if we can't find the entry
            break unless result

            result
          end
        end
      end
    end
  end
end
