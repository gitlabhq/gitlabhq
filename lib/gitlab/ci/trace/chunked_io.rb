##
# This class is compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
# source: https://gitlab.com/snippets/1685610
module Gitlab
  module Ci
    class Trace
      class ChunkedIO
        attr_reader :size
        attr_reader :tell
        attr_reader :chunk, :chunk_range

        alias_method :pos, :tell

        def initialize(size)
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

        def read(length = nil)
          out = ""

          until eof? || (length && out.length >= length)
            data = get_chunk
            break if data.empty?

            out << data
            @tell += data.bytesize
          end

          out = out[0, length] if length && out.length > length

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
        # To be overridden by superclasses
        #
        def get_chunk
          raise NotImplementedError
        end

        def in_range?
          @chunk_range&.include?(tell)
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
