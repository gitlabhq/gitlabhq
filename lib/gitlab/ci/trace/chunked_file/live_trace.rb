module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class LiveTrace < ChunkedIO
          class << self
            def exist?(job_id)
              ChunkStores::Redis.chunks_count(job_id) > 0 ||
                ChunkStores::Database.chunks_count(job_id) > 0
            end
          end

          def initialize(job_id, mode)
            super(job_id, calculate_size(job_id), mode)
          end

          def write(data)
            raise NotImplementedError, 'Overwrite is not supported' unless tell == size

            super(data) do |store|
              if store.filled?
                # Once data is filled into redis, move the data to database
                ChunkStore::Database.open(job_id, chunk_index, params_for_store) do |to_store|
                  to_store.write!(store.get)
                  store.delete!
                end
              end
            end
          end

          def truncate(offset)
            super(offset) do |store|
              next if chunk_index == 0

              prev_chunk_index = chunk_index - 1

              if ChunkStore::Database.exist?(job_id, prev_chunk_index)
                # Swap data from Database to Redis to truncate any size than buffer_size
                ChunkStore::Database.open(job_id, prev_chunk_index, params_for_store(prev_chunk_index)) do |from_store|
                  ChunkStore::Redis.open(job_id, prev_chunk_index, params_for_store(prev_chunk_index)) do |to_store|
                    to_store.write!(from_store.get)
                    from_store.delete!
                  end
                end
              end
            end
          end

          private

          def calculate_size(job_id)
            ChunkStore::Redis.chunks_size(job_id) +
              ChunkStore::Database.chunks_size(job_id)
          end

          def chunk_store
            if last_chunk?
              ChunkStore::Redis
            else
              ChunkStore::Database
            end
          end

          def buffer_size
            128.kilobytes
          end
        end
      end
    end
  end
end
