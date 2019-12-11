# frozen_string_literal: true
#
module Gitlab
  module DiscussionsDiff
    class HighlightCache
      class << self
        VERSION = 1
        EXPIRATION = 1.week

        # Sets multiple keys to a given value. The value
        # is serialized as JSON.
        #
        # mapping - Write multiple cache values at once
        def write_multiple(mapping)
          Redis::Cache.with do |redis|
            redis.multi do |multi|
              mapping.each do |raw_key, value|
                key = cache_key_for(raw_key)

                multi.set(key, value.to_json, ex: EXPIRATION)
              end
            end
          end
        end

        # Reads multiple cache keys at once.
        #
        # raw_keys - An Array of unique cache keys, without namespaces.
        #
        # It returns a list of deserialized diff lines. Ex.:
        # [[Gitlab::Diff::Line, ...], [Gitlab::Diff::Line]]
        def read_multiple(raw_keys)
          return [] if raw_keys.empty?

          keys = raw_keys.map { |id| cache_key_for(id) }

          content =
            Redis::Cache.with do |redis|
              redis.mget(keys)
            end

          content.map! do |lines|
            next unless lines

            JSON.parse(lines).map! do |line|
              Gitlab::Diff::Line.safe_init_from_hash(line)
            end
          end
        end

        # Clears multiple cache keys at once.
        #
        # raw_keys - An Array of unique cache keys, without namespaces.
        #
        # It returns the number of cache keys cleared. Ex.: 42
        def clear_multiple(raw_keys)
          return [] if raw_keys.empty?

          keys = raw_keys.map { |id| cache_key_for(id) }

          Redis::Cache.with { |redis| redis.del(keys) }
        end

        def cache_key_for(raw_key)
          "#{cache_key_prefix}:#{raw_key}"
        end

        private

        def cache_key_prefix
          "#{Redis::Cache::CACHE_NAMESPACE}:#{VERSION}:discussion-highlight"
        end
      end
    end
  end
end
