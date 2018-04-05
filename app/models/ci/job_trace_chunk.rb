module Ci
  class JobTraceChunk < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id

    after_destroy :redis_delete_data, if: :redis?

    default_value_for :data_store, :redis

    CHUNK_SIZE = 32.kilobytes
    CHUNK_REDIS_TTL = 1.month

    enum data_store: {
      redis: 1,
      db: 2,
    }

    def data
      case 
      when redis?
        redis_data
      when db?
        raw_data
      else
        raise 'Unsupported data store'
      end
    end

    def set_data(value)
      raise 'too much data' if value.bytesize > CHUNK_SIZE

      case
      when redis?
        redis_set_data(value)
      when db?
        self.raw_data = value
      else
        raise 'Unsupported data store'
      end

      save! if changed?
      schedule_to_db if fullfilled?
    end

    def truncate(offset = 0)
      self.append("", offset)
    end

    def append(new_data, offset)
      current_data = self.data || ""
      raise 'Offset is out of bound' if offset > current_data.bytesize || offset < 0
      raise 'Outside of chunk size' if CHUNK_SIZE < offset + new_data.bytesize

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
      return if db?
      return unless size > 0

      self.update!(raw_data: data, data_store: :db)
      redis_delete_data
    end

    private

    def schedule_to_db
      return if db?

      StashTraceChunkWorker.perform_async(id)
    end

    def fullfilled?
      size == CHUNK_SIZE
    end

    def redis_data
      Gitlab::Redis::SharedState.with do |redis|
        redis.get(redis_key)
      end
    end

    def redis_set_data(data)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(redis_key, data, ex: CHUNK_REDIS_TTL)
      end
    end

    def redis_delete_data
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(redis_key)
      end
    end

    def redis_key
      "gitlab:ci:trace:#{job_id}:chunks:#{chunk_index}"
    end
  end
end
