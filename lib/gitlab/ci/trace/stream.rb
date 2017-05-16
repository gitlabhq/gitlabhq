module Gitlab
  module Ci
    class Trace
      # This was inspired from: http://stackoverflow.com/a/10219411/1520132
      class Stream
        BUFFER_SIZE = 4096
        LIMIT_SIZE = 500.kilobytes

        attr_reader :stream

        delegate :close, :tell, :seek, :size, :path, :truncate, to: :stream, allow_nil: true

        delegate :valid?, to: :stream, as: :present?, allow_nil: true

        def initialize
          @stream = yield
          @stream&.binmode
        end

        def valid?
          self.stream.present?
        end

        def file?
          self.path.present?
        end

        def limit(last_bytes = LIMIT_SIZE)
          if last_bytes < size
            stream.seek(-last_bytes, IO::SEEK_END)
            stream.readline
          end
        end

        def append(data, offset)
          stream.truncate(offset)
          stream.seek(0, IO::SEEK_END)
          stream.write(data)
          stream.flush()
        end

        def set(data)
          truncate(0)
          stream.write(data)
          stream.flush()
        end

        def raw(last_lines: nil)
          return unless valid?

          if last_lines.to_i > 0
            read_last_lines(last_lines)
          else
            stream.read
          end.force_encoding(Encoding.default_external)
        end

        def html_with_state(state = nil)
          ::Ci::Ansi2html.convert(stream, state)
        end

        def html(last_lines: nil)
          text = raw(last_lines: last_lines)
          buffer = StringIO.new(text)
          ::Ci::Ansi2html.convert(buffer).html
        end

        def extract_coverage(regex)
          return unless valid?
          return unless regex

          regex = Regexp.new(regex)

          match = ""

          reverse_line do |line|
            matches = line.scan(regex)
            next unless matches.is_a?(Array)
            next if matches.empty?

            match = matches.flatten.last
            coverage = match.gsub(/\d+(\.\d+)?/).first
            return coverage if coverage.present?
          end

          nil
        rescue
          # if bad regex or something goes wrong we dont want to interrupt transition
          # so we just silentrly ignore error for now
        end

        private

        def read_last_lines(last_lines)
          chunks = []
          pos = lines = 0
          max = stream.size

          # We want an extra line to make sure fist line has full contents
          while lines <= last_lines && pos < max
            pos += BUFFER_SIZE

            buf =
              if pos <= max
                stream.seek(-pos, IO::SEEK_END)
                stream.read(BUFFER_SIZE)
              else # Reached the head, read only left
                stream.seek(0)
                stream.read(BUFFER_SIZE - (pos - max))
              end

            lines += buf.count("\n")
            chunks.unshift(buf)
          end

          chunks.join.lines.last(last_lines).join
        end

        def reverse_line
          pos = BUFFER_SIZE
          max = stream.size
          debris = ''

          while pos < max
            stream.seek(-pos, IO::SEEK_END)
            stream.read(BUFFER_SIZE).tap do |buf|
              buf = buf + debris
              debris, *lines = buf.each_line.to_a
              lines.reverse_each do |line|
                yield(line)
              end
            end
            pos += BUFFER_SIZE
          end

          # Reached the head, read only left
          stream.seek(0)
          last = (max > BUFFER_SIZE) ? (max % BUFFER_SIZE) : max
          stream.read(last).tap do |buf|
            buf = buf + debris
            buf.each_line.reverse_each do |line|
              yield(line)
            end
          end
        end
      end
    end
  end
end
