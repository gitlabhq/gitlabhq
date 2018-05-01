module Ci
  class BuildTraceChunk < ActiveRecord::Base
    include FastDestroyAll
    extend Gitlab::Ci::Model

    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id

    default_value_for :data_store, :redis
    fast_destroy_all_with :delete_all_redis_data, :redis_all_data_keys

    WriteError = Class.new(StandardError)

    CHUNK_SIZE = 128.kilobytes
    CHUNK_REDIS_TTL = 1.week
    WRITE_LOCK_RETRY = 100
    WRITE_LOCK_SLEEP = 1
    WRITE_LOCK_TTL = 5.minutes

    enum data_store: {
      redis: 1,
      db: 2
    }

    class << self
      def redis_data_key(build_id, chunk_index)
        "gitlab:ci:trace:#{build_id}:chunks:#{chunk_index}"
      end

      def redis_all_data_keys
        redis.pluck(:build_id, :chunk_index).map do |data|
          redis_data_key(data.first, data.second)
        end
      end

      def delete_all_redis_data(redis_keys)
        if redis_keys.any?
          Gitlab::Redis::SharedState.with do |redis|
            redis.del(redis_keys)
          end
        end
      end
    end

    ##
    # Data is memoized for optimizing #size and #end_offset
    def data
      @data ||= get_data.to_s
    end

    def truncate(offset = 0)
      self.append("", offset) if offset < size
    end

    def append(new_data, offset)
      raise ArgumentError, 'Offset is out of range' if offset > data.bytesize || offset < 0
      raise ArgumentError, 'Chunk size overflow' if CHUNK_SIZE < (offset + new_data.bytesize)

      set_data(data.byteslice(0, offset) + new_data)
    end

    def size
      data&.bytesize.to_i
    end

    def start_offset
      chunk_index * CHUNK_SIZE
    end

    def end_offset
      start_offset + size
    end

    def range
      (start_offset...end_offset)
    end

    def use_database!
      in_lock do
        break if db?
        break unless size > 0

        self.update!(raw_data: data, data_store: :db)
        redis_delete_data
      end
    end

    private

    def get_data
      if redis?
        redis_data
      elsif db?
        raw_data
      else
        raise 'Unsupported data store'
      end&.force_encoding(Encoding::BINARY) # Redis/Database return UTF-8 string as default
    end

    def set_data(value)
      raise ArgumentError, 'too much data' if value.bytesize > CHUNK_SIZE

      in_lock do
        if redis?
          redis_set_data(value)
        elsif db?
          self.raw_data = value
        else
          raise 'Unsupported data store'
        end

        @data = value

        save! if changed?
      end

      schedule_to_db if fullfilled?
    end

    def schedule_to_db
      return if db?

      BuildTraceSwapChunkWorker.perform_async(id)
    end

    def fullfilled?
      size == CHUNK_SIZE
    end

    def redis_data
      Gitlab::Redis::SharedState.with do |redis|
        redis.get(self.class.redis_data_key(build_id, chunk_index))
      end
    end

    def redis_set_data(data)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(self.class.redis_data_key(build_id, chunk_index), data, ex: CHUNK_REDIS_TTL)
      end
    end

    def redis_delete_data
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(self.class.redis_data_key(build_id, chunk_index))
      end
    end

    def redis_lock_key
      "trace_write:#{build_id}:chunks:#{chunk_index}"
    end

    def in_lock
      lease = Gitlab::ExclusiveLease.new(redis_lock_key, timeout: WRITE_LOCK_TTL)
      retry_count = 0

      until uuid = lease.try_obtain
        # Keep trying until we obtain the lease. To prevent hammering Redis too
        # much we'll wait for a bit between retries.
        sleep(WRITE_LOCK_SLEEP)
        break if WRITE_LOCK_RETRY < (retry_count += 1)
      end

      raise WriteError, 'Failed to obtain write lock' unless uuid

      self.reload if self.persisted?
      return yield
    ensure
      Gitlab::ExclusiveLease.cancel(redis_lock_key, uuid)
    end
  end
end
