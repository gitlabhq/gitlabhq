module Gitlab
  module Ci
    class Trace
      class Remote < ChunkedIO
        BUFFER_SIZE = 128.kilobytes

        NoSupportError = Class.new(StandardError)

        attr_reader :uri

        def initialize(job_id, url, size, mode)
          @uri = URI(url)

          super(job_id, size, mode)
        end

        def write(data)
          raise NoSupportError
        end

        def truncate(offset)
          raise NoSupportError
        end

        def flush
          raise NoSupportError
        end

        private

        def chunk_store
          ChunkStores::Http
        end

        def params_for_store
          super.merge( { uri: uri } )
        end
      end
    end
  end
end
