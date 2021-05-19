# frozen_string_literal: true

if Gitlab::Runtime.puma?
  # This patch represents https://github.com/puma/puma/pull/2613. If
  # this PR is accepted in the next Puma release, we can remove this
  # entire file.
  #
  # The patch itself is quite large because the tempfile creation in
  # Puma is inside these fairly long methods. The actual changes are
  # just two lines, commented with 'GitLab' to make them easier to find.
  raise "Remove this monkey patch: #{__FILE__}" unless Puma::Const::VERSION == '5.1.1'

  module Puma
    class Client
      private

      def setup_body
        @body_read_start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

        if @env[HTTP_EXPECT] == CONTINUE
          # TODO allow a hook here to check the headers before
          # going forward
          @io << HTTP_11_100
          @io.flush
        end

        @read_header = false

        body = @parser.body

        te = @env[TRANSFER_ENCODING2]

        if te
          if te.include?(",")
            te.split(",").each do |part|
              if CHUNKED.casecmp(part.strip) == 0 # rubocop:disable Metrics/BlockNesting
                return setup_chunked_body(body)
              end
            end
          elsif CHUNKED.casecmp(te) == 0
            return setup_chunked_body(body)
          end
        end

        @chunked_body = false

        cl = @env[CONTENT_LENGTH]

        unless cl
          @buffer = body.empty? ? nil : body
          @body = EmptyBody
          set_ready
          return true
        end

        remain = cl.to_i - body.bytesize

        if remain <= 0
          @body = StringIO.new(body)
          @buffer = nil
          set_ready
          return true
        end

        if remain > MAX_BODY
          @body = Tempfile.new(Const::PUMA_TMP_BASE)
          @body.binmode
          @body.unlink # GitLab: this is the changed part
          @tempfile = @body
        else
          # The body[0,0] trick is to get an empty string in the same
          # encoding as body.
          @body = StringIO.new body[0,0] # rubocop:disable Layout/SpaceAfterComma
        end

        @body.write body

        @body_remain = remain

        return false # rubocop:disable Style/RedundantReturn
      end

      def setup_chunked_body(body)
        @chunked_body = true
        @partial_part_left = 0
        @prev_chunk = ""

        @body = Tempfile.new(Const::PUMA_TMP_BASE)
        @body.binmode
        @body.unlink # GitLab: this is the changed part
        @tempfile = @body
        @chunked_content_length = 0

        if decode_chunk(body)
          @env[CONTENT_LENGTH] = @chunked_content_length
          return true # rubocop:disable Style/RedundantReturn
        end
      end
    end
  end
end
