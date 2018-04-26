module Ci
  class BuildTraceChunk < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id

    after_destroy :redis_delete_data, if: :redis?

    default_value_for :data_store, :redis

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

    def data
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

        save! if changed?
      end

      schedule_to_db if fullfilled?
    end

    def truncate(offset = 0)
      self.append("", offset)
    end

    def append(new_data, offset)
      current_data = self.data.to_s
      raise ArgumentError, 'Offset is out of bound' if offset > current_data.bytesize || offset < 0
      raise ArgumentError, 'Outside of chunk size' if CHUNK_SIZE < offset + new_data.bytesize

      self.set_data(current_data.byteslice(0, offset) + new_data)
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

    def schedule_to_db
      return if db?

      BuildTraceSwapChunkWorker.perform_async(id)
    end

    def fullfilled?
      size == CHUNK_SIZE
    end

    def redis_data
      Gitlab::Redis::SharedState.with do |redis|
        redis.get(redis_data_key)
      end
    end

    def redis_set_data(data)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(redis_data_key, data, ex: CHUNK_REDIS_TTL)
      end
    end

    def redis_delete_data
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(redis_data_key)
      end
    end

    def redis_data_key
      "gitlab:ci:trace:#{build_id}:chunks:#{chunk_index}:data"
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
