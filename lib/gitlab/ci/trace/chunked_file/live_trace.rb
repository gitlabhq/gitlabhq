module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class LiveTrace < ChunkedIO
          BUFFER_SIZE = 128.kilobytes

          class << self
            def open(job_id, mode)
              stream = self.class.new(job_id, mode)

              yield stream

              stream.close
            end

            def exist?(job_id)
              ChunkStores::Redis.chunks_count(job_id) > 0 ||
                ChunkStores::Database.chunks_count(job_id) > 0
            end
          end

          def initialize(job_id, mode)
            super(job_id, calculate_size, mode)
          end

          def write(data)
            raise NotImplementedError, 'Overwrite is not supported' unless tell == size

            super(data) do |store|
              if store.filled?
                # Rotate data from redis to database
                ChunkStores::Database.open(job_id, chunk_index, params_for_store) do |to_store|
                  to_store.write!(store.get)
                end

                store.delete!
              end
            end
          end

          private

          def calculate_size
            ChunkStores::Redis.chunks_size(job_id) + 
              ChunkStores::Database.chunks_size(job_id)
          end

          def chunk_store
            if last_chunk?
              ChunkStores::Redis
            else
              ChunkStores::Database
            end
          end
        end
      end
    end
  end
end
