##
# This class is compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
# source: https://gitlab.com/snippets/1685610
module Gitlab
  module Ci
    class Trace
      class HttpIO
        BUFFER_SIZE = 128.kilobytes

        attr_reader :uri, :size
        attr_reader :tell
        attr_reader :chunk, :chunk_range

        alias_method :pos, :tell

        def initialize(url, size)
          @uri = URI(url)
          @size = size
          @tell = 0
        end

        def close
        end

        def binmode
          # no-op
        end

        def path
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
          loop !eof? do
            line = readline
            yield(line)
          end
        end

        def read(length = nil)
          out = ""

          while length.nil? || out.length < length
            data = get_chunk
            break if data.empty?

            out += data
            @tell += data.bytesize
          end

          if length && out.length > length
            extra = out.length - length
            out = out[0..-extra]
          end

          out
        end

        def readline
          out = ""

          loop !eof? do
            data = get_chunk
            new_line = data.index("\n")

            if !new_line.nil?
              out += data[0..new_line]
              @tell += new_line + 1
              break
            else
              out += data
              @tell += data.bytesize
            end
          end

          out
        end

        def write(data)
          throw NotImplementedException
        end

        def truncate(offset)
          throw NotImplementedException
        end

        def flush
          throw NotImplementedException
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

            @chunk = response.body.force_encoding(Encoding::BINARY)
            @chunk_range = response.content_range
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
