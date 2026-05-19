# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        # Service class for batched fetching of CI config file content with Redis caching.
        #
        # Handles the pattern of:
        # 1. Checking Redis cache for requested paths
        # 2. Batching uncached items into a single Gitaly call
        # 3. Writing fetched content back to cache
        #
        # Used by both project includes and component includes for efficient content fetching.
        class CachedContentFetcher
          CACHE_EXPIRY = 4.hours

          def initialize(project:, cache_enabled:)
            @project = project
            @cache_enabled = cache_enabled
          end

          def read_cache(cache_key)
            return unless cache_enabled

            repository_cache.read(cache_key)
          end

          def fetch_batch(items)
            return {} if items.empty?
            return fetch_from_gitaly(items) unless cache_enabled

            cached_content, items_to_fetch = check_cache(items)
            cached_content.merge!(fetch_from_gitaly(items_to_fetch)) unless items_to_fetch.empty?

            cached_content
          end

          private

          attr_reader :project, :cache_enabled

          def check_cache(items)
            items.reduce([{}, []]) do |(cached_content, items_to_fetch), (path, cache_key)|
              cached = repository_cache.read(cache_key)

              if cached
                cached_content[path] = cached
              else
                items_to_fetch << [path, cache_key]
              end

              [cached_content, items_to_fetch]
            end
          end

          def fetch_from_gitaly(items)
            blob_requests = items.map { |sha_path, _cache_key| sha_path }
            blobs = project.repository.blobs_at(blob_requests)
            blob_map = blobs.index_by { |blob| [blob.commit_id, blob.path] }

            items.each_with_object({}) do |(sha_path, cache_key), results|
              content = blob_map[sha_path]&.data

              next unless content

              repository_cache.write(cache_key, content, expires_in: CACHE_EXPIRY) if cache_enabled
              results[sha_path] = content
            end
          end

          def repository_cache
            Gitlab::Redis::RepositoryCache.cache_store
          end
        end
      end
    end
  end
end
