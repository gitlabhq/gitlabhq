module Gitlab
  module Ci
    class Trace
      module ChunkStores
        class Database < Base
          class << self
            def open(job_id, chunk_index, **params)
              raise ArgumentError unless job_id && chunk_index

              job = Ci::JobTraceChunk.find_or_initialize_by(job_id: job_id, chunk_index: chunk_index)

              yield self.class.new(job, params)
            end

            def exist?(job_id, chunk_index)
              Ci::JobTraceChunk.exists?(job_id: job_id, chunk_index: chunk_index)
            end

            def chunks_count(job_id)
              Ci::JobTraceChunk.where(job_id: job_id).count
            end

            def chunks_size(job_id)
              Ci::JobTraceChunk.where(job_id: job_id).pluck('len(data)')
                .inject(0){ |sum, data_length| sum + data_length }
            end

            def delete_all(job_id)
              Ci::JobTraceChunk.destroy_all(job_id: job_id)
            end
          end

          attr_reader :job

          def initialize(job, **params)
            super

            @job = job
          end

          def get
            job.data
          end

          def size
            job.data&.length || 0
          end

          def write!(data)
            raise NotSupportedError, 'Only full size is supported' unless buffer_size == data.length

            job.create!(data: data)

            data.length
          end

          def truncate!(offset)
            raise NotSupportedError
          end

          def delete!
            job.destroy!
          end

          # def change_chunk_index!(job_id, new_chunk_index)
          #   raise NotSupportedError
          # end
        end
      end
    end
  end
end
