# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      # Cookie is a serialization format we use to minimize the number of keys
      # we read, write and delete in Redis. Keys and values must be strings.
      # Newlines are not allowed in either keys or values. Keys cannot contain
      # '='. This format has the useful property that serialize(h1) +
      # serialize(h2) == h1.merge(h2).
      class Cookie
        def self.serialize(hash)
          hash.map { |k, v| "#{k}=#{v}\n" }.join
        end

        def self.deserialize(string)
          string.each_line(chomp: true).to_h { |line| line.split('=', 2) }
        end

        def initialize(key)
          @key = key
        end

        def set(hash, expiry)
          with_redis { |redis| redis.set(@key, self.class.serialize(hash), nx: true, ex: expiry) }
        end

        def get
          with_redis { |redis| self.class.deserialize(redis.get(@key) || '') }
        end

        def del
          with_redis { |redis| redis.del(@key) }
        end

        def append(hash)
          with_redis do |redis|
            redis.eval(
              # Only append if the keys exists. This way we are not responsible for
              # setting the expiry of the key: that is the responsibility of #set.
              'if redis.call("exists", KEYS[1]) > 0 then redis.call("append", KEYS[1], ARGV[1]) end',
              keys: [@key],
              argv: [self.class.serialize(hash)]
            )
          end
        end

        def with_redis(&block)
          if Feature.enabled?(:use_primary_and_secondary_stores_for_duplicate_jobs) ||
              Feature.enabled?(:use_primary_store_as_default_for_duplicate_jobs)
            # TODO: Swap for Gitlab::Redis::SharedState after store transition
            # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/923
            Gitlab::Redis::DuplicateJobs.with(&block) # rubocop:disable CodeReuse/ActiveRecord
          else
            # Keep the old behavior intact if neither feature flag is turned on
            Sidekiq.redis(&block) # rubocop:disable Cop/SidekiqRedisCall
          end
        end
      end
    end
  end
end
