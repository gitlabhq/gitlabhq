module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        class HttpIO < ChunkedIO
          BUFFER_SIZE = 128.kilobytes

          InvalidURLError = Class.new(StandardError)

          attr_reader :uri

          def initialize(job_id, url, size, mode)
            raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

            @uri = URI(url)

            super(job_id, size, mode)
          end

          def write(data)
            raise NotImplementedError
          end

          def truncate(offset)
            raise NotImplementedError
          end

          def flush
            raise NotImplementedError
          end

          private

          def chunk_store
            ChunkStores::ObjectStorage
          end

          def params_for_store
            super.merge( { uri: uri } )
          end
        end
      end
    end
  end
end
