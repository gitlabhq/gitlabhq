# frozen_string_literal: true

module ObjectStorage
  class PendingDirectUpload
    KEY = 'pending_direct_uploads'

    def self.prepare(location_identifier, path)
      ::Gitlab::Redis::SharedState.with do |redis|
        # We need to store the location_identifier together with the timestamp to properly delete
        # this object if ever this upload gets stale. The location identifier will be used
        # by the clean up worker to properly generate the storage options through ObjectStorage::Config.for_location
        redis.hset(KEY, key(location_identifier, path), Time.current.utc.to_i)
      end
    end

    def self.exists?(location_identifier, path)
      ::Gitlab::Redis::SharedState.with do |redis|
        redis.hexists(KEY, key(location_identifier, path))
      end
    end

    def self.complete(location_identifier, path)
      ::Gitlab::Redis::SharedState.with do |redis|
        redis.hdel(KEY, key(location_identifier, path))
      end
    end

    def self.key(location_identifier, path)
      [location_identifier, path].join(':')
    end
  end
end
