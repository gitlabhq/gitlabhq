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
            matches = line.force_encoding(regex.encoding).scan(regex)
            next unless matches.is_a?(Array)
            next if matches.empty?

            match = matches.flatten.last
            coverage = match.gsub(/\d+(\.\d+)?/).first
            return coverage if coverage.present?
          end

          nil
        rescue
          # if bad regex or something goes wrong we dont want to interrupt transition
          # so we just silently ignore error for now
        end

        private

        def read_last_lines(limit)
          to_enum(:reverse_line).first(limit).reverse.join
        end

        def reverse_line
          pos = 0
          max = stream.size
          debris = ''

          while (read_size = calc_read_size(pos, max)) > 0
            pos += read_size
            stream.seek(-pos, IO::SEEK_END)
            stream.read(read_size).tap do |buf|
              buf = buf + debris
              debris, *lines = buf.each_line.to_a
              lines.reverse_each do |line|
                yield(line)
              end
            end
          end

          yield(debris) if debris != ''
        end

        def calc_read_size(pos, max)
          if pos > max
            BUFFER_SIZE + (pos - max)
          else
            remain = max - pos
            (remain > BUFFER_SIZE) ? BUFFER_SIZE : remain
          end
        end
      end
    end
  end
end
