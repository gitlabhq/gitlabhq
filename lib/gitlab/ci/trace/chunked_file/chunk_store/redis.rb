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

              def delete_all(job_id)
                Gitlab::Redis::Cache.with do |redis|
                  redis.scan_each(:match => buffer_key(job_id, '?')) do |key|
                    redis.del(key)
                  end
                end
              end

              def buffer_key(job_id, chunk_index)
                "live_trace_buffer:#{job_id}:#{chunk_index}"
              end
            end

            BufferKeyNotFoundError = Class.new(StandardError)
            WriteError = Class.new(StandardError)

            attr_reader :buffer_key

            def initialize(buffer_key, **params)
              super

              @buffer_key = buffer_key
            end

            def close
              @buffer_key = nil
            end

            def get
              puts "#{self.class.name} - #{__callee__}: params[:chunk_index]: #{params[:chunk_index]}"

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
              raise ArgumentError, 'Could not write empty data' unless data.present?

              puts "#{self.class.name} - #{__callee__}: data.length: #{data.length.inspect} params[:chunk_index]: #{params[:chunk_index]}"
              Gitlab::Redis::Cache.with do |redis|
                unless redis.set(buffer_key, data) == 'OK'
                  raise WriteError, 'Failed to write'
                end

                redis.strlen(buffer_key)
              end
            end

            def append!(data)
              raise ArgumentError, 'Could not write empty data' unless data.present?

              puts "#{self.class.name} - #{__callee__}: data.length: #{data.length.inspect} params[:chunk_index]: #{params[:chunk_index]}"
              Gitlab::Redis::Cache.with do |redis|
                raise BufferKeyNotFoundError, 'Buffer key is not found' unless redis.exists(buffer_key)

                original_size = size
                new_size = redis.append(buffer_key, data)
                appended_size = new_size - original_size

                raise WriteError, 'Failed to append' unless appended_size == data.length

                appended_size
              end
            end

            def truncate!(offset)
              raise NotImplementedError
            end

            def delete!
              puts "#{self.class.name} - #{__callee__}: params[:chunk_index]: #{params[:chunk_index]}"
              Gitlab::Redis::Cache.with do |redis|
                raise BufferKeyNotFoundError, 'Buffer key is not found' unless redis.exists(buffer_key)

                unless redis.del(buffer_key) == 1
                  raise WriteError, 'Failed to delete'
                end
              end
            end
          end
        end
      end
    end
  end
end
