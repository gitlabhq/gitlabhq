module Gitlab
  module Ci
    class Trace
      class HttpIO < ChunkedIO
        FailedToGetChunkError = Class.new(StandardError)
        InvalidURLError = Class.new(StandardError)

        BUFFER_SIZE = 128.kilobytes

        attr_reader :uri

        def initialize(url, size)
          raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

          @uri = URI(url)

          super
        end

        def url
          @uri.to_s
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

        ##
        # Override
        def get_chunk
          unless in_range?
            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
              http.request(request)
            end

            raise FailedToGetChunkError unless response.code == '200' || response.code == '206'

            @chunk = response.body.force_encoding(Encoding::BINARY)
            @chunk_range = response.content_range

            ##
            # Note: If provider does not return content_range, then we set it as we requested
            # Provider: minio
            # - When the file size is larger than requested Content-range, the Content-range is included in responces with Net::HTTPPartialContent 206
            # - When the file size is smaller than requested Content-range, the Content-range is included in responces with Net::HTTPPartialContent 206
            # Provider: AWS
            # - When the file size is larger than requested Content-range, the Content-range is included in responces with Net::HTTPPartialContent 206
            # - When the file size is smaller than requested Content-range, the Content-range is included in responces with Net::HTTPPartialContent 206
            # Provider: GCS
            # - When the file size is larger than requested Content-range, the Content-range is included in responces with Net::HTTPPartialContent 206
            # - When the file size is smaller than requested Content-range, the Content-range is included in responces with Net::HTTPOK 200
            @chunk_range ||= (chunk_start...(chunk_start + @chunk.length))
          end

          @chunk[chunk_offset..BUFFER_SIZE]
        end

        def request
          Net::HTTP::Get.new(uri).tap do |request|
            request.set_range(chunk_start, BUFFER_SIZE)
          end
        end
      end
    end
  end
end
