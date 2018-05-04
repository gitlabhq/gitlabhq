##
# This class is compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
# source: https://gitlab.com/snippets/1685610
module Gitlab
  module Ci
    class Trace
      class HttpIO
        BUFFER_SIZE = 128.kilobytes

        InvalidURLError = Class.new(StandardError)
        FailedToGetChunkError = Class.new(StandardError)

        attr_reader :uri, :size
        attr_reader :tell
        attr_reader :chunk, :chunk_range

        alias_method :pos, :tell

        def initialize(url, size)
          raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

          @uri = URI(url)
          @size = size
          @tell = 0
        end

        def close
          # no-op
        end

        def binmode
          # no-op
        end

        def binmode?
          true
        end

        def path
          nil
        end

        def url
          @uri.to_s
        end

        def seek(pos, where = IO::SEEK_SET)
          new_pos =
            case where
            when IO::SEEK_END
              size + pos
            when IO::SEEK_SET
              pos
            when IO::SEEK_CUR
              tell + pos
            else
              -1
            end

          raise 'new position is outside of file' if new_pos < 0 || new_pos > size

          @tell = new_pos
        end

        def eof?
          tell == size
        end

        def each_line
          until eof?
            line = readline
            break if line.nil?

            yield(line)
          end
        end

        def read(length = nil, outbuf = "")
          out = ""

          length ||= size - tell

          until length <= 0 || eof?
            data = get_chunk
            break if data.empty?

            chunk_bytes = [BUFFER_SIZE - chunk_offset, length].min
            chunk_data = data.byteslice(0, chunk_bytes)

            out << chunk_data
            @tell += chunk_data.bytesize
            length -= chunk_data.bytesize
          end

          # If outbuf is passed, we put the output into the buffer. This supports IO.copy_stream functionality
          if outbuf
            outbuf.slice!(0, outbuf.bytesize)
            outbuf << out
          end

          out
        end

        def readline
          out = ""

          until eof?
            data = get_chunk
            new_line = data.index("\n")

            if !new_line.nil?
              out << data[0..new_line]
              @tell += new_line + 1
              break
            else
              out << data
              @tell += data.bytesize
            end
          end

          out
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

        def present?
          true
        end

        private

        ##
        # The below methods are not implemented in IO class
        #
        def in_range?
          @chunk_range&.include?(tell)
        end

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
            @chunk_range ||= (chunk_start...(chunk_start + @chunk.bytesize))
          end

          @chunk[chunk_offset..BUFFER_SIZE]
        end

        def request
          Net::HTTP::Get.new(uri).tap do |request|
            request.set_range(chunk_start, BUFFER_SIZE)
          end
        end

        def chunk_offset
          tell % BUFFER_SIZE
        end

        def chunk_start
          (tell / BUFFER_SIZE) * BUFFER_SIZE
        end

        def chunk_end
          [chunk_start + BUFFER_SIZE, size].min
        end
      end
    end
  end
end
