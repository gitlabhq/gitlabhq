module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module ChunkStore
          class Database < Base
            class << self
              def open(job_id, chunk_index, **params)
                raise ArgumentError unless job_id && chunk_index

                job_trace_chunk = ::Ci::JobTraceChunk
                  .find_or_initialize_by(job_id: job_id, chunk_index: chunk_index)
                store = self.new(job_trace_chunk, params)

                yield store
              ensure
                store&.close
              end

              def exist?(job_id, chunk_index)
                ::Ci::JobTraceChunk.exists?(job_id: job_id, chunk_index: chunk_index)
              end

              def chunks_count(job_id)
                ::Ci::JobTraceChunk.where(job_id: job_id).count
              end

              def chunks_size(job_id)
                ::Ci::JobTraceChunk.where(job_id: job_id).pluck('data')
                  .inject(0) { |sum, data| sum + data.length }
              end
            end

            attr_reader :job_trace_chunk

            def initialize(job_trace_chunk, **params)
              super

              @job_trace_chunk = job_trace_chunk
            end

            def close
              @job_trace_chunk = nil
            end

            def get
              job_trace_chunk.data
            end

            def size
              job_trace_chunk.data&.length || 0
            end

            def write!(data)
              raise NotImplementedError, 'Partial write is not supported' unless buffer_size == data&.length
              raise NotImplementedError, 'UPDATE is not supported' if job_trace_chunk.data

              job_trace_chunk.data = data
              job_trace_chunk.save!

              data.length
            end

            def append!(data)
              raise NotImplementedError
            end

            def truncate!(offset)
              raise NotImplementedError
            end

            def delete!
              job_trace_chunk.destroy!
            end
          end
        end
      end
    end
  end
end
