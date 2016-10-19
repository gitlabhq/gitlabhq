module Gitlab
  module Ci
    # This was inspired from: http://stackoverflow.com/a/10219411/1520132
    class TraceReader
      BUFFER_SIZE = 4096

      attr_accessor :path, :buffer_size

      def initialize(new_path, buffer_size: BUFFER_SIZE)
        self.path = new_path
        self.buffer_size = Integer(buffer_size)
      end

      def read(last_lines: nil)
        if last_lines
          read_last_lines(last_lines)
        else
          File.read(path)
        end
      end

      def read_last_lines(max_lines)
        File.open(path) do |file|
          chunks = []
          pos = lines = 0
          max = file.size

          # We want an extra line to make sure fist line has full contents
          while lines <= max_lines && pos < max
            pos += buffer_size

            buf = if pos <= max
                    file.seek(-pos, IO::SEEK_END)
                    file.read(buffer_size)
                  else # Reached the head, read only left
                    file.seek(0)
                    file.read(buffer_size - (pos - max))
                  end

            lines += buf.count("\n")
            chunks.unshift(buf)
          end

          chunks.join.lines.last(max_lines).join
        end
      end
    end
  end
end
