# frozen_string_literal: true
#
module Gitlab
  module DiscussionsDiff
    class HighlightCache
      extend Gitlab::Utils::Gzip

      class << self
        VERSION = 1
        EXPIRATION = 1.week

        # Sets multiple keys to a given value. The value
        # is serialized as JSON.
        #
        # mapping - Write multiple cache values at once
        def write_multiple(mapping)
          with_redis do |redis|
            Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              redis.pipelined do |pipelined|
                mapping.each do |raw_key, value|
                  key = cache_key_for(raw_key)

                  pipelined.set(key, gzip_compress(value.to_json), ex: EXPIRATION)
                end
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
            with_redis do |redis|
              Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
                if Gitlab::Redis::ClusterUtil.cluster?(redis)
                  redis.pipelined do |pipeline|
                    keys.each { |key| pipeline.get(key) }
                  end
                else
                  redis.mget(keys)
                end
              end
            end

          content.map! do |lines|
            next unless lines

            Gitlab::Json.parse(gzip_decompress(lines.force_encoding(Encoding::UTF_8))).map! do |line|
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

          with_redis do |redis|
            Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              if Gitlab::Redis::ClusterUtil.cluster?(redis)
                Gitlab::Redis::ClusterUtil.batch_unlink(keys, redis)
              else
                redis.del(keys)
              end
            end
          end
        end

        def cache_key_for(raw_key)
          "#{cache_key_prefix}:#{raw_key}"
        end

        private

        def cache_key_prefix
          "#{Redis::Cache::CACHE_NAMESPACE}:#{VERSION}:discussion-highlight"
        end

        def with_redis(&block)
          Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
