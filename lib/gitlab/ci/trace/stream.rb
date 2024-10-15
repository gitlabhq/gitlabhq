# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      class Stream
        BUFFER_SIZE = 4096
        LIMIT_SIZE = 500.kilobytes

        TIMESTAMP_HEADER_DATETIME = '\d{4}-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]\.[0-9]{6}Z'
        TIMESTAMP_HEADER_DATETIME_LENGTH = 27
        TIMESTAMP_HEADER_REGEX = /(#{TIMESTAMP_HEADER_DATETIME}) [0-9a-f]{2}[EO][+ ]/
        TIMESTAMP_HEADER_LENGTH = 32

        attr_reader :stream, :metrics

        delegate :close, :tell, :seek, :size, :url, :truncate, to: :stream, allow_nil: true

        def initialize(metrics = Trace::Metrics.new)
          @stream = yield
          @stream&.binmode
          @metrics = metrics
          @timestamped = nil
        end

        def valid?
          self.stream.present?
        end
        alias_method :present?, :valid?

        def file?
          self.path.present?
        end

        def path
          self.stream.path if self.stream.respond_to?(:path)
        end

        def limit(last_bytes = LIMIT_SIZE)
          if last_bytes < size
            stream.seek(-last_bytes, IO::SEEK_END)
            stream.readline
          end
        end

        def append(data, offset)
          data = data.force_encoding(Encoding::BINARY)

          metrics.increment_trace_operation(operation: :streamed)
          metrics.increment_trace_bytes(data.bytesize)

          stream.seek(offset, IO::SEEK_SET)
          stream.write(data)
          stream.truncate(offset + data.bytesize)
          stream.flush
        end

        def set(data)
          append(data, 0)
        end

        def raw(last_lines: nil, max_size: nil)
          return unless valid?

          if max_size.to_i > 0
            read_last_lines_with_max_size(last_lines, max_size)
          elsif last_lines.to_i > 0
            read_last_lines(last_lines)
          else
            stream.read
          end.force_encoding(Encoding.default_external)
        end

        def html(last_lines: nil, max_size: nil)
          text = raw(last_lines: last_lines, max_size: max_size)
          buffer = StringIO.new(text)
          ::Gitlab::Ci::Ansi2html.convert(buffer).html
        end

        def extract_coverage(regex)
          return unless valid?
          return unless regex.present?

          regex = Gitlab::UntrustedRegexp.new(regex)

          match = ""
          strip_timestamp = has_timestamps?

          reverse_line do |line|
            line.chomp!

            # strip timestamp from line
            line.slice!(0, TIMESTAMP_HEADER_LENGTH) if strip_timestamp

            matches = regex.scan(line)
            next unless matches.is_a?(Array)
            next if matches.empty?

            match = matches.flatten.last
            coverage = match.gsub(/\d+(\.\d+)?/).first
            return coverage if coverage.present? # rubocop:disable Cop/AvoidReturnFromBlocks
          end

          nil
        rescue StandardError
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

        def read_last_lines_with_max_size(limit, max_size)
          linesleft = limit
          result = ''

          reverse_line_with_max_size(max_size) do |line|
            result = line + result
            unless linesleft.nil?
              linesleft -= 1
              break if linesleft <= 0
            end
          end

          result
        end

        def reverse_line_with_max_size(max_size)
          stream.seek(0, IO::SEEK_END)
          debris = ''
          sizeleft = max_size

          until sizeleft <= 0 || (buf = read_backward([BUFFER_SIZE, sizeleft].min)).empty?
            sizeleft -= buf.bytesize
            debris, *lines = (buf + debris).each_line.to_a
            lines.reverse_each do |line|
              yield(line.force_encoding(Encoding.default_external))
            end
          end

          yield(debris.force_encoding(Encoding.default_external)) unless debris.empty?
        end

        def reverse_line
          stream.seek(0, IO::SEEK_END)
          debris = ''

          until (buf = read_backward(BUFFER_SIZE)).empty?
            debris, *lines = (buf + debris).each_line.to_a
            lines.reverse_each do |line|
              yield(line.force_encoding(Encoding.default_external))
            end
          end

          yield(debris.force_encoding(Encoding.default_external)) unless debris.empty?
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

        def has_timestamps?
          return @timestamped unless @timestamped.nil?

          cur_offset = stream.tell
          stream.seek(0, IO::SEEK_SET)
          line = stream.readline.chomp
          stream.seek(cur_offset, IO::SEEK_SET)

          @timestamped = TIMESTAMP_HEADER_REGEX.match?(line)
          @timestamped
        end
      end
    end
  end
end
