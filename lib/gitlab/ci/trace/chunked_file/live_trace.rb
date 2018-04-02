module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class LiveTrace < ChunkedIO
          class << self
            def exist?(job_id)
              ChunkStore::Redis.chunks_count(job_id) > 0 || ChunkStore::Database.chunks_count(job_id) > 0
            end
          end

          after_callback :write_chunk, :stash_to_database

          def stash_to_database(store)
            # Once data is filled into redis, move the data to database
            if store.filled?
              ChunkStore::Database.open(job_id, chunk_index, params_for_store) do |to_store|
                to_store.write!(store.get)
                store.delete!
              end
            end
          end

          # This is more efficient than iterating each chunk store and deleting
          def truncate(offset)
            if offset == 0
              delete
            elsif offset == size
              # no-op
            else
              raise NotImplementedError, 'Unexpected operation'
            end
          end

          def delete
            ChunkStore::Redis.delete_all(job_id)
            ChunkStore::Database.delete_all(job_id)
          end

          private

          def calculate_size(job_id)
            ChunkStore::Redis.chunks_size(job_id) +
              ChunkStore::Database.chunks_size(job_id)
          end

          def chunk_store
            if last_range.include?(tell)
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
