# frozen_string_literal: true

module ObjectStorage
  class PendingDirectUpload
    include ObjectStorage::FogHelpers

    KEY = 'pending_direct_uploads'
    MAX_UPLOAD_DURATION = 3.hours.freeze

    def self.prepare(location_identifier, object_storage_path)
      with_redis do |redis|
        # We need to store the location_identifier together with the timestamp to properly delete
        # this object if ever this upload gets stale. The location identifier will be used
        # by the clean up worker to properly generate the storage options through ObjectStorage::Config.for_location
        key = redis_key(location_identifier, object_storage_path)
        redis.hset(KEY, key, Time.current.utc.to_i)
        log_event(:prepared, key)
      end
    end

    def self.with_pending_only(location_identifier, object_storage_paths)
      with_redis do |redis|
        keys = object_storage_paths.map do |path|
          redis_key(location_identifier, path)
        end

        matches = redis.hmget(KEY, keys)
        index = -1
        object_storage_paths.select do
          index += 1
          matches[index].present?
        end
      end
    end

    def self.exists?(location_identifier, object_storage_path)
      with_redis do |redis|
        redis.hexists(KEY, redis_key(location_identifier, object_storage_path))
      end
    end

    def self.complete(location_identifier, object_storage_path)
      with_redis do |redis|
        key = redis_key(location_identifier, object_storage_path)
        redis.hdel(KEY, key)
        log_event(:completed, key)
      end
    end

    def self.redis_key(location_identifier, object_storage_path)
      [location_identifier, object_storage_path].join(':')
    end

    def self.count
      with_redis do |redis|
        redis.hlen(KEY)
      end
    end

    def self.each
      with_redis do |redis|
        redis.hscan_each(KEY) do |entry|
          redis_key, timestamp = entry
          storage_location_identifier, object_storage_path = redis_key.split(':')

          object = new(
            redis_key: redis_key,
            storage_location_identifier: storage_location_identifier,
            object_storage_path: object_storage_path,
            timestamp: timestamp
          )

          yield(object)
        end
      end
    end

    def self.with_redis(&block)
      Gitlab::Redis::SharedState.with(&block) # rubocop:disable CodeReuse/ActiveRecord
    end

    def self.log_event(event, redis_key)
      Gitlab::AppLogger.info(
        message: "Pending direct upload #{event}",
        redis_key: redis_key
      )
    end

    def initialize(redis_key:, storage_location_identifier:, object_storage_path:, timestamp:)
      @redis_key = redis_key
      @storage_location_identifier = storage_location_identifier.to_sym
      @object_storage_path = object_storage_path
      @timestamp = timestamp.to_i
    end

    def stale?
      timestamp < MAX_UPLOAD_DURATION.ago.utc.to_i
    end

    def delete
      delete_object(object_storage_path)

      self.class.with_redis do |redis|
        redis.hdel(self.class::KEY, redis_key)
        self.class.log_event(:deleted, redis_key)
      end
    end

    private

    attr_reader :redis_key, :storage_location_identifier, :object_storage_path, :timestamp
  end
end
