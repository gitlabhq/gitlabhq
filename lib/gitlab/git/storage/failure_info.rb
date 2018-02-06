module Gitlab
  module Git
    module Storage
      class FailureInfo
        attr_accessor :first_failure, :last_failure, :failure_count

        def self.reset_all!
          Gitlab::Git::Storage.redis.with do |redis|
            all_storage_keys = redis.zrange(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, -1)
            redis.del(*all_storage_keys) unless all_storage_keys.empty?
          end

          RequestStore.delete(:circuitbreaker_cache)
        end

        def self.load(cache_key)
          first_failure, last_failure, failure_count = Gitlab::Git::Storage.redis.with do |redis|
            redis.hmget(cache_key, :first_failure, :last_failure, :failure_count)
          end

          last_failure = Time.at(last_failure.to_i) if last_failure.present?
          first_failure = Time.at(first_failure.to_i) if first_failure.present?

          new(first_failure, last_failure, failure_count.to_i)
        end

        def initialize(first_failure, last_failure, failure_count)
          @first_failure = first_failure
          @last_failure = last_failure
          @failure_count = failure_count
        end

        def no_failures?
          first_failure.blank? && last_failure.blank? && failure_count == 0
        end
      end
    end
  end
end
