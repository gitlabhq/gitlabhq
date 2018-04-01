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

          after_callback :write_chunk, :stash_to_database

          def initialize(job_id, mode)
            super(job_id, calculate_size(job_id), mode)
          end

          def stash_to_database(store)
            # Once data is filled into redis, move the data to database
            if store.filled? && 
              ChunkStore::Database.open(job_id, chunk_index, params_for_store) do |to_store|
                to_store.write!(store.get)
                store.delete!
              end
            end
          end

          # Efficient process than iterating each
          def truncate(offset)
            if truncate == 0
              delete
            elsif offset == size
              # no-op
            else
              raise NotImplementedError, 'Unexpected operation'
            end
          end

          def present?
            self.exist?(job_id)
          end

          def delete
            ChunkStores::Redis.delete_all(job_id)
            ChunkStores::Database.delete_all(job_id)
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
