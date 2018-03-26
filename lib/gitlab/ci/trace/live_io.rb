module Gitlab
  module Ci
    class Trace
      class LiveIO < ChunkedIO
        BUFFER_SIZE = 32.kilobytes

        class << self
          def exists?(job_id)
            exists_in_redis? || exists_in_database?
          end

          def exists_in_redis?(job_id)
            Gitlab::Redis::Cache.with do |redis|
              redis.exists(buffer_key(job_id))
            end
          end

          def exists_in_database?(job_id)
            Ci::JobTraceChunk.exists?(job_id: job_id)
          end

          def buffer_key(job_id)
            "ci:live_trace_buffer:#{job_id}"
          end
        end

        attr_reader :job_id

        def initialize(job_id)
          @job_id = job_id

          super
        end

        def write(data)
          # TODO: 
        end

        def truncate(offset)
          # TODO: 
        end

        def flush
          # TODO: 
        end

        private

        ##
        # Override
        def get_chunk
          # TODO: 
        end
      end
    end
  end
end
