module Gitlab
  module Ci
    class Trace
      # This was inspired from: http://stackoverflow.com/a/10219411/1520132
      class Stream
        BUFFER_SIZE = 4096
        LIMIT_SIZE = 500.kilobytes

        attr_reader :stream

        delegate :close, :tell, :seek, :size, :path, :url, :truncate, to: :stream, allow_nil: true

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
          ::Gitlab::Ci::Ansi2html.convert(stream, state)
        end

        def html(last_lines: nil)
          text = raw(last_lines: last_lines)
          buffer = StringIO.new(text)
          ::Gitlab::Ci::Ansi2html.convert(buffer).html
        end

        def extract_coverage(regex)
          return unless valid?
          return unless regex.present?

          regex = Gitlab::UntrustedRegexp.new(regex)

          match = ""

          reverse_line do |line|
            line.chomp!
            matches = regex.scan(line)
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

        def extract_sections
          return [] unless valid?

          lines = to_enum(:each_line_with_pos)
          parser = SectionParser.new(lines)

          parser.parse!
          parser.sections
        end

        private

        def each_line_with_pos
          stream.seek(0, IO::SEEK_SET)
          stream.each_line do |line|
            yield [line, stream.pos - line.bytesize]
          end
        end

        def read_last_lines(limit)
          to_enum(:reverse_line).first(limit).reverse.join
        end

        def reverse_line
          stream.seek(0, IO::SEEK_END)
          debris = ''

          until (buf = read_backward(BUFFER_SIZE)).empty?
            buf += debris
            debris, *lines = buf.each_line.to_a
            lines.reverse_each do |line|
              yield(line.force_encoding('UTF-8'))
            end
          end

          yield(debris.force_encoding('UTF-8')) unless debris.empty?
        end

        def read_backward(length)
          cur_offset = stream.tell
          start = cur_offset - length
          start = 0 if start < 0

          stream.seek(start, IO::SEEK_SET)
          stream.read(cur_offset - start).tap do
            stream.seek(start, IO::SEEK_SET)
          end
        end
      end
    end
  end
end
