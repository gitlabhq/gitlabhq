module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module ChunkStore
          class Redis < Base
            class << self
              def open(job_id, chunk_index, **params)
                raise ArgumentError unless job_id && chunk_index

                buffer_key = self.buffer_key(job_id, chunk_index)
                store = self.new(buffer_key, params)

                yield store
              ensure
                store&.close
              end

              def exist?(job_id, chunk_index)
                Gitlab::Redis::Cache.with do |redis|
                  redis.exists(self.buffer_key(job_id, chunk_index))
                end
              end

              def chunks_count(job_id)
                Gitlab::Redis::Cache.with do |redis|
                  redis.scan_each(:match => buffer_key(job_id, '?')).inject(0) do |sum, key|
                    sum + 1
                  end
                end
              end

              def chunks_size(job_id)
                Gitlab::Redis::Cache.with do |redis|
                  redis.scan_each(:match => buffer_key(job_id, '?')).inject(0) do |sum, key|
                    sum += redis.strlen(key)
                  end
                end
              end

              def buffer_key(job_id, chunk_index)
                "live_trace_buffer:#{job_id}:#{chunk_index}"
              end
            end

            attr_reader :buffer_key

            def initialize(buffer_key, **params)
              super

              @buffer_key = buffer_key
            end

            def close
              @buffer_key = nil
            end

            def get
              Gitlab::Redis::Cache.with do |redis|
                redis.get(buffer_key)
              end
            end

            def size
              Gitlab::Redis::Cache.with do |redis|
                redis.strlen(buffer_key)
              end
            end

            def write!(data)
              Gitlab::Redis::Cache.with do |redis|
                redis.set(buffer_key, data)
                redis.strlen(buffer_key)
              end
            end

            def truncate!(offset)
              Gitlab::Redis::Cache.with do |redis|
                return unless redis.exists(buffer_key)

                truncated_data = redis.getrange(buffer_key, 0, offset)
                redis.set(buffer_key, truncated_data)
              end
            end

            def delete!
              Gitlab::Redis::Cache.with do |redis|
                redis.del(buffer_key)
              end
            end
          end
        end
      end
    end
  end
end
