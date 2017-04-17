module Gitlab
  module Ci
    class Trace
      # This was inspired from: http://stackoverflow.com/a/10219411/1520132
      class Stream
        BUFFER_SIZE = 4096
        LIMIT_SIZE = 50.kilobytes

        attr_reader :stream

        delegate :close, :tell, :seek, :size, :path, :truncate, to: :stream, allow_nil: true

        delegate :valid?, to: :stream, as: :present?, allow_nil: true

        def initialize
          @stream = yield
          if @stream
            @stream.binmode
            # Ci::Ansi2html::Converter would read from @stream directly,
            # using @stream.each_line to be specific. It's safe to set
            # the encoding here because IO#seek(bytes) and IO#read(bytes)
            # are not characters based, so encoding doesn't matter to them.
            @stream.set_encoding(Encoding.default_external)
          end
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
          stream = StringIO.new(text)
          ::Ci::Ansi2html.convert(stream).html
        end

        def extract_coverage(regex)
          return unless valid?
          return unless regex

          regex = Regexp.new(regex)

          match = ""

          stream.each_line do |line|
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
      end
    end
  end
end
